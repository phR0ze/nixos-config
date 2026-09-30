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
- **Runtime secrets** (`hosts/<name>/secrets.enc.yaml`): decrypted by sops-nix at activation to
  `/run/secrets`; never touches the store or git. `host.sopsFile` is forwarded into each module that
  needs it. **Prefer this** for anything only a running service reads.

**Isolated hosts**: an empty `hosts/<name>/.isolated` marker skips both root layers (`args.nix` and
`args.dec.yaml`) - the host must be self-contained. Pair with a dedicated sops age key in
`.sops.yaml`. Example: `hosts/vps`.

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
