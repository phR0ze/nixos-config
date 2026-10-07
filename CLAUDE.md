# NixOS Configuration Repository

Multi-host NixOS config. `./clu` (bash, commands in `lib/`) wraps the single root `flake.nix`, which
generates one `nixosConfigurations.<hostname>` per `hosts/<hostname>/` directory. Adding a host is
just creating that directory.

## Agent Rules

- **Never run `./clu build` or `./clu update`.** They invoke `nixos-rebuild` / long evaluations the
  user must run themselves. Make the change and tell the user which command to run.
- When no host is named ("my config", "this machine"), run `hostname` - it matches the
  `hosts/<hostname>/` directory.
- Never use `--impure`. Pure evaluation is a deliberate constraint.

## Secrets: Two Mechanisms (don't conflate them)

- **Build-time args** (`args.enc.yaml` -> `args.dec.yaml`, root and per-host): only for values a
  NixOS option needs at *evaluation* time (drive UUIDs, NIC config, EFI/MBR). Flakes only see
  git-tracked files, so `lib/flake` decrypts just the one target host's files, `git add -f`s them,
  and an `EXIT` trap unstages/deletes them after. `clu clean dec` sweeps leftovers from a crash.
- **Runtime secrets** (root `secrets.enc.yaml` + `hosts/<name>/secrets.enc.yaml`): decrypted by
  sops-nix at activation to `/run/secrets`; never touches the store or git. `host.sopsFile` is
  forwarded into each module that needs it. **Prefer this** for anything only a running service reads.

**A host's runtime secrets are two files, not one** - unless the host is `.isolated`:

- **Normal hosts**: `clu`'s `flake::decrypt_secrets` (`lib/flake`) merges the fleet-shared root
  `secrets.enc.yaml` with `hosts/<name>/secrets.enc.yaml` (host wins on conflict) into a transient
  `hosts/<name>/secrets.merged.enc.yaml`, which `host.sopsFile` resolves to first. A key absent
  from the host file is **not** missing if root has it (e.g. `alerts/ntfyTopic` lives only in
  root) - always check both files before calling a secret missing.
- **`.isolated` hosts**: no merge; root is never read. Only `hosts/<name>/secrets.enc.yaml`
  counts, so a key absent from it really is missing.
- A bare `nix eval` outside `clu` has no merged file, so `host.sopsFile` falls back to the host file
  alone - it does **not** reflect what a real build sees for a normal host.

**Isolated hosts**: an empty `hosts/<name>/.isolated` marker skips every root layer - `args.nix`,
`args.dec.yaml` and the root `secrets.enc.yaml` merge - so the host must be self-contained. Pair
with a dedicated sops age key in `.sops.yaml`. Examples: `hosts/vps1`, `hosts/vm-vps1`.

## Networking: networkd + NetworkManager (`modules/devices/network.nix`)

- **systemd-networkd owns all wired config** (DHCP, static IP, bridge, macvlan) as native
  `systemd.network` units. systemd-resolved is the only resolver.
- **NetworkManager is an optional desktop overlay** that handles WiFi and nm-applet tray status. On
  hosts with a static IP or bridge it only *observes* networkd's primary interface ("connected
  (externally)") and never configures it. With neither, NM owns everything and networkd is idle.
- NM only adopts an interface as external if networkd has already configured it when NM starts.
  Otherwise NM claims the interface and flushes networkd's config. So NM is started after networkd
  settles the primary interface, with a short carrier check and no wait if no cable is connected.
- **Boot never waits on networking.** Nothing in the boot path may depend on NM, wait-online or
  `network-online.target`. Network-dependent units retry, or list themselves in
  `devices.network.onlineServices` to be started by `network-services.target` once the network is
  up, after boot (never via `wantedBy multi-user` + `after network-online`).

## Args Composition (`mergeArgs` in `flake.nix`, low -> high)

1. `args.nix` 2. `args.dec.yaml` 3. `hosts/<name>/args.nix` 4. `hosts/<name>/args.dec.yaml`,
then `hostname` and `git.comment` are always set by `flake.nix` itself. Result is passed as
`specialArgs = { args f inputs }`.

Always merge with `lib.recursiveUpdate` - a top-level `//` silently clobbers nested attrsets.

A flake input only one host needs is declared unconditionally in `flake.nix` and referenced
conditionally in `mkHost` (see `macbook` / `nixos-hardware`).

## Modules

`modules/default.nix` imports every module and all of `layers/`, so every option exists on every
host. Consequently:

- **Every module must have an `enable` option and gate all config behind `lib.mkIf cfg.enable`** -
  no exceptions, no always-on modules, even if only one layer ever enables it.
- `modules/default.nix` also declares the `host.*` option (defaults from `args`) and translates it
  into real options. Shared values are forwarded into services with small enable-gated blocks:
  ```nix
  (lib.mkIf config.services.native.caddy.enable {
    services.native.caddy.sopsFile = cfg.sopsFile;
    services.native.caddy.baseDomain = cfg.network.domain;
  })
  ```
  The receiving option must be nullable/empty by default, with the real requirement as an
  enable-gated assertion in the module. Host-specific service values not in `host.*` come from
  `f.getServiceAttr "<ns>.<name>.<field>"`.
- Option-specific custom package builds go in `package.nix` beside the module (`default.nix` is the
  option definition); general ones in `packages/<name>/`, wired up in `modules/nixpkgs.nix`.

## Layers

A layer is an option namespace (`layers.<group>.<name>`), not an import unit - same shape as any
module, turning on a coherent set of features. Hosts activate them in `config`.

- **Never `imports` another layer.** Chain by enabling it in your config
  (`layers/console/desktop.nix` -> `server.nix` -> `core.nix` is the reference).
- Pass flags down as `lib.mkIf cfg.flag true`, **not** `cfg.flag` - a bare `false` conflicts with
  another layer that wants it on.
- Prefer a new flag on an existing layer (e.g. `harden`) over a new layer.
- Register a new layer by adding it to `layers/<group>/default.nix` imports (new groups go in
  `layers/default.nix`).

**Migration in progress**: `layers/console/*` uses this model. `layers/{xfce,plasma,budgie,bundles}`
are old-style (ungated config imported via bundles) - convert them as you touch them; `bundles/`
goes away. `layers/iso.nix` is the deliberate exception (imported directly by `flake.nix` for ISO
builds). `clu install`'s picker (`lib/install`) still greps for `# - Directly installable:` markers
and imports file paths; it needs to switch to setting `enable` as layers migrate.
