# NixOS Configuration Repository

A multi-host NixOS configuration managing 22+ physical and virtual hosts through a custom bash
automation layer (`clu`) that orchestrates Nix flake evaluation. Host selection is a real, standard
per-host `nixosConfigurations.<hostname>` flake entry, generated from each `hosts/<hostname>/`
directory. The one thing `clu` still has to stage before evaluation is each host's *build-time args*
(`hosts/<hostname>/args.enc.yaml`, decrypted to `args.dec.yaml`) - Nix flakes only see git-tracked
or staged files, and some of that data (drive UUIDs, network interface config, EFI/MBR selection) is
genuinely needed by NixOS module options at evaluation time, so it can't be deferred to sops-nix's
normal activation-time secret decryption. This staging is scoped to exactly one host per build and
reverted immediately after via a `trap ... EXIT`.

---

## 1. The `clu` Bash Framework

### Entry Point: `/clu`

The main CLI script. Sources `lib/all` which loads every module in `lib/`. Parses a command and
dispatches to `<command>::run()`.

### Commands

`lib/all` sources every `lib/<command>` file; each defines `<command>::run()` and
`<command>::usage()`, dispatched from `clu`'s main case statement. Run `clu help` or `ls lib/` for
the current command list - don't rely on a table here, it drifts.

---

## 2. Host Selection & Build-Time Args (`lib/flake`)

The flake generates one real `nixosConfigurations.<hostname>` entry per `hosts/<hostname>/`
directory (see `mkHost` in `flake.nix`) - there's no symlink or per-invocation file copying
involved in selecting a host. `nixosConfigurations` is a lazy attrset, so `nix build
.#<hostname>...` only forces evaluation of that one host; every other (still-encrypted) host's
args are never touched.

**What still needs staging**: `hosts/<hostname>/args.dec.yaml` and root `args.dec.yaml` - the
decrypted forms of `args.enc.yaml`. Some of that data (drive UUIDs, network config, EFI/MBR) is
consumed by NixOS module options at evaluation time, and Nix flakes only see git-tracked/staged files,
so there's no way around staging without `--impure` (deliberately avoided - see §7).

**The `flake::switch(target)` function** (called before every build/update), for a `hosts/*`
target:
1. Runs `flake::decrypt_args(hostname)`: `sops --decrypt` on root `args.enc.yaml` and
   `hosts/<hostname>/args.enc.yaml` (whichever exist) to `args.dec.yaml` siblings, then
   `git add -f`s them.
2. Remembers the hostname in `_FLAKE_ARGS_HOST` so `flake::restore` knows what to clean up, without
   depending on the format of whatever the caller's `$HOST`/`$TARGET` variables happen to be.

Layer-only targets (`layers/*`, e.g. ISO builds) skip this entirely - there's no per-host args to
decrypt, and ISO builds deliberately exclude secrets (`layers/iso_args.nix`).

**`flake::restore()`** unstages and deletes the one host's `args.dec.yaml` files. A `trap ...  EXIT`
in every caller ensures this runs even on failure, so a crash leaves at most one host's plaintext
behind (`clu clean dec` sweeps up any leftovers via the broader `utils::remove_decrypted`).

**`flake::stage_files(target)`** is the full workflow wrapper: removes `/nix/files.lock`, calls
`flake::switch`, sets the restore trap.

**Isolated hosts**: a host directory containing an empty `hosts/<hostname>/.isolated` marker file
opts out of *both* root layers (root `args.nix` and root `args.dec.yaml`) in `mergeArgs` - it must
be fully self-contained in its own `args.nix`/`args.dec.yaml`, and `lib/flake`'s decrypt step skips
`args.enc.yaml` for it too. This is for hosts that need to be walled off from the fleet's shared
config/secrets (e.g. an internet-facing VPS): a compromise of this host shouldn't expose the
fleet's shared args, and a fleet-key compromise shouldn't expose this host's args either (pair it
with a dedicated sops age key in `.sops.yaml`). See `hosts/vps` for the live example.

### Why This Matters for Feature Work

- All `nixos-rebuild`/`nix build`/`nixos-install` commands use `--flake "${CONFIG_DIR}#${HOST}"`
  (the real hostname), not a generic `#target` name.
- `args.nix` at root is a normal, permanently committed file now - nothing mutates it per build.
  `hostname` and `git.comment` in the final merged `args` are always set authoritatively by
  `flake.nix` itself (from the `hosts/` directory name and `self.rev`, respectively), never read
  from a file, so they can't drift.
- Adding a new host means creating a `hosts/<name>/` directory - nothing else to touch.

---

## 3. Flake Structure (`flake.nix`)

There is exactly one `flake.nix` (and `flake.lock`), permanently committed at the repo root - no
more `base.nix`/per-machine `flake.nix` copy-swapping. Only `macbook` needs an extra flake input
(`nixos-hardware`, for the `apple-t2` module); since flake inputs can't be conditional on which
host is being built, it's declared unconditionally in `flake.nix` and only referenced by `mkHost`
when `hostname == "macbook"` - follow this pattern for any future host-specific input. See
`flake.nix` for the current input/output list.

### Argument Composition (Priority Low -> High)
`mergeArgs hostname` in `flake.nix`:
1. `args.nix` - Base defaults (committed)
2. `args.dec.yaml` - Base secrets (decrypted at build time)
3. `hosts/<hostname>/args.nix` - Host-specific overrides
4. `hosts/<hostname>/args.dec.yaml` - Host-specific secrets
5. `hostname` and `git.comment` are then always set authoritatively (directory name / `self.rev`),
   overriding anything the above files might otherwise supply

Steps 1-2 (both root layers) are skipped entirely for a host with a `hosts/<hostname>/.isolated`
marker - see §2.

Merged via `lib.recursiveUpdate` (careful: a plain `//` at the top level would silently clobber
nested attrsets like `git.*` - always use `lib.recursiveUpdate` when overriding a leaf) and passed as
`specialArgs = { inherit args f inputs; }`, computed once per host inside `mkHost`.

### Overlays
Injected via `nixpkgs.overlays` in `modules/nixpkgs.nix` (not `flake.nix`) - custom package builds
plus a handful of `nixpkgs-unstable` version overrides. See that file for the current list.

---

## 4. Directory Structure

```
clu                    # Bash entry point
lib/                   # Bash library modules (one per command)
flake.nix / flake.lock # The single shared flake (permanently committed)
args.nix               # Default arguments (static, committed - never mutated by clu)
modules/               # All NixOS modules - every one is an opt-in feature namespace (see §5)
modules/default.nix    #   Imports every module + declares the `host` type and its forwarding (see §5)
modules/types/         #   Reusable option submodule types (nic, dns, user, service, caddy_proxy)
layers/                # Chainable `layers.<group>.<name>` option namespaces, auto-imported (see §6)
hosts/<name>/          # Per-host configurations (22+ hosts) - configuration.nix, hardware-configuration.nix,
                       #   args.enc.yaml/args.nix, secrets.enc.yaml, optionally .isolated (see §2)
include/               # Static file templates (home dir configs, fonts, nix cache keys)
packages/              # Custom package definitions, referenced by overlays in modules/nixpkgs.nix
funcs/                 # Nix helper functions
.sops.yaml             # Secrets management config (age encryption)
```

---

## 5. Option Architecture

### Pattern

Every option follows a consistent structure:

```nix
{ config, lib, pkgs, ... }:
let cfg = config.<namespace>.<name>;
in {
  options.<namespace>.<name> = {
    enable = lib.mkEnableOption "Description";
    # additional typed options...
  };
  config = lib.mkIf (cfg.enable) {
    # NixOS configuration applied when enabled
  };
}
```

**Every module requires an explicit `enable` option - no exceptions.** There is no "always-on
baseline" category: a module must never apply config merely by being imported. `modules/default.nix`
imports *everything* - every `modules/*` subdirectory and all of `layers/` - so every option in the
repo is defined on every host and imports carry no meaning beyond that. `enable` is the only thing
that turns config on. This holds even for modules only one layer ever activates (e.g.
`modules/system/users.nix`, `modules/system/locale.nix`, `modules/system/env/systemd.nix`) - that
layer sets `<namespace>.<name>.enable = true;` and the module's own `lib.mkIf (cfg.enable)` gate is
what applies it. This keeps every module independently testable/toggleable and keeps
`configuration.nix` diffs honest about what's actually turned on for a host.

### The `host` Type (`modules/default.nix`)

`modules/default.nix` does two things: it imports every module in the repo, and it declares the
`host` option - the central hub defining all host-level configuration. Every field defaults from
the composed `args` attribute set (see §3). This is what lets layers/hosts stay DRY across 22+
hosts: `modules/default.nix`'s own `config` block translates `host.*` into the real NixOS/module
options it implements (`networking.*`, `devices.*`, `services.*`, ...) instead of every host
repeating that config directly. Representative fields: `host.type.*` (capability flags like `vm`),
`host.network.*` (networking, including `host.network.domain`), `host.sopsFile` (nullable path to
that host's `secrets.enc.yaml`), `host.services` (free-form `services.<ns>.<name>.*` values from
args) - see `modules/default.nix` for the full option set, it's the source of truth and this list
will go stale otherwise.

**Forwarding a shared value into a service.** Rather than every host's `configuration.nix`
repeating the same domain/secrets path, `modules/default.nix` ends with one small `enable`-gated
block per service that needs fleet-shared data:

```nix
(lib.mkIf config.services.native.caddy.enable {
  services.native.caddy.sopsFile = cfg.sopsFile;
  services.native.caddy.baseDomain = cfg.network.domain;
})
```

The receiving option must therefore be *nullable/empty by default* so the forward is unconditional,
with the real requirement expressed as an `enable`-gated assertion inside the module itself (see
`services.oci.pangolin`'s `baseDomain`/`acmeEmail` and `services.native.caddy`'s
`sopsFile`/`baseDomain`). Host-specific values that aren't already a `host.*` field come from
`host.services` via `f.getServiceAttr "<ns>.<name>.<field>"` - keyed the same as the real option
path minus the leading `services.`.

---

## 6. Layers

**A layer is an option namespace, not an import unit.** `modules/default.nix` imports `../layers`,
which fans out through `layers/default.nix` to every layer file, so every layer's *options* exist on
every host for free. Importing a layer applies nothing - its config sits behind its own
`layers.<group>.<name>.enable` gate, exactly like every other module (§5). A host activates what it
wants from its own `config`:

```nix
config = {
  layers.console.server = {
    enable = true;
    harden = true;
    lowMemory = true;
  };
};
```

A layer is just a module whose job is to turn on a coherent set of `modules/*` features: feature
enables (`apps.system.neovim.enable = true`), `environment.systemPackages` lists, and machine flags.

### Chaining

Layers compose by **setting each other's options**, never by importing each other. A layer that
builds on a lower one enables it in its own `config` block and passes shared flags down, so one
top-level toggle propagates through the chain:

```nix
config = lib.mkIf (cfg.enable) {
  layers.console.core = {
    enable = true;
    lowMemory = lib.mkIf cfg.lowMemory true;
  };
};
```

`layers/console/desktop.nix` -> `server.nix` -> `core.nix` is the live example: a host enabling
`desktop` with `harden = true` gets `server` and `core` enabled with hardening carried down.

Pass flags along as `lib.mkIf cfg.flag true`, **not** `cfg.flag` - a bare `false` is a real value
that fights with another activated layer that wanted the flag on. With `mkIf`, a chain only ever
adds.

### Shape of a layer

Same as any module (§5), plus the `mkMerge` split for flags:

```nix
{ config, lib, pkgs, ... }:
let cfg = config.layers.<group>.<name>;
in {
  options.layers.<group>.<name> = {
    enable = lib.mkEnableOption "Enable the <name> layer";
    harden = lib.mkEnableOption "Enable security hardening configuration";
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) { /* base config + chained layer enables */ })
    (lib.mkIf (cfg.enable && cfg.harden) { /* variant config */ })
  ];
}
```

Flags are why the layer count stays small: a hardened server is `server` with `harden = true`, not a
separate `server-hardened` layer. Reach for a new flag on an existing layer before a new layer.

### Migration status

`layers/console/*` follows this model. `layers/xfce/*`, `layers/plasma/*`, `layers/budgie/*` and
`layers/bundles/*` are still the old style - bare `config` bodies with no `enable` gate, aggregated
by a `bundles/` module that the host `imports` - and most hosts still import a bundle. Convert them
to `layers.<group>.<name>` namespaces as you touch them; `layers/bundles/` disappears in the
process, since a bundle is just a layer that enables other layers. `layers/iso.nix` is the one
deliberate exception - `flake.nix` imports it directly as the ISO build's entry point.

---

## 7. Secrets Management

Two distinct mechanisms exist, used for two genuinely different needs - don't conflate them:

**Build-time args** (`args.enc.yaml` -> `args.dec.yaml`, used for data a NixOS module option needs
at *evaluation* time - drive UUIDs, network interface config, EFI/MBR selection):
- **Tool**: sops with age encryption, decrypted by the operator's local `sops` CLI/age key
- **Config**: `.sops.yaml` at repo root with age public key
- **Lifecycle**: `flake::decrypt_args(hostname)` decrypts just that host's files before build,
  `flake::restore`/`flake::restore_args` clean up after (scoped to one host); `clu clean dec`
  (`utils::remove_decrypted`, repo-wide) is the manual safety net for anything left behind by a crash
- **Git integration**: `git add -f`'d temporarily so pure flake evaluation can see them, then unstaged
  - this is unavoidable without `--impure` (deliberately not used - it would require reading
  decrypted content from outside the flake's evaluated source tree, which isn't self-contained)
- **ISO exclusion**: ISO builds use `layers/iso_args.nix` instead of secrets

**Runtime secrets** (`secrets.enc.yaml`, used for credentials only a running service needs -
passwords, SMB share creds): decrypted by **sops-nix at systemd activation time**, straight to
`/run/secrets`/`/run/files` on the target host - never touches the Nix store, git, or this repo's
working tree at all. `host.sopsFile` is the single per-host path to that file, forwarded by
`modules/default.nix` into every module that needs it (`system.users.sopsFile` for the user
password hash, `services.native.smb.sopsFile` for SMB share creds, `services.native.caddy.sopsFile`
for the Cloudflare DNS-01 token, `services.native.adguardhome.sopsFile`,
`services.native.vaultwarden.sopsFile`, `services.oci.pangolin.sopsFile`) - each of those then
declares its own `secret.files`/`secret.templates` entries against it. Prefer this over the build-time-args mechanism whenever a value is only consumed
by a running service reading a file, not by a NixOS module option at evaluation time.

---

## 8. Conventions for Adding Features

### Adding a New Host
`<name>` becomes the real `nixosConfigurations.<name>` flake attribute automatically just by
creating `hosts/<name>/` - nothing else to register. Use `args.enc.yaml` only for values a module
option needs at *evaluation* time; use `secrets.enc.yaml` for everything else (see §7 - this
distinction is easy to get backwards). If the host needs to be walled off from the fleet's shared
config/secrets, add an empty `hosts/<name>/.isolated` marker and a dedicated sops age key (§2). If
the host needs a flake input no other host uses, add it unconditionally to the root `flake.nix`
and reference it conditionally in `mkHost` (see `macbook`/`nixos-hardware`).

### Adding a New Package Overlay
Custom package builds go in `packages/<name>/`; option-specific custom builds use `package.nix`
in the option's own directory (not `default.nix`, which is reserved for the option definition).

### Adding a New Layer
Create `layers/<group>/<name>.nix` declaring `options.layers.<group>.<name>` with an `enable` plus
any flags, and add the file to `layers/<group>/default.nix`'s `imports` (for a new group, create
that `default.nix` and add the directory to `layers/default.nix`). That's registration - it makes
the options available everywhere, not the config (§6).

- **Never `imports` another layer.** Depend on it by enabling it in your `config` block and passing
  flags through with `lib.mkIf cfg.flag true`.
- **Prefer a flag on an existing layer** over a new layer for a variant of one.
- `clu install`'s interactive picker (`lib/install`) still discovers installable targets by grepping
  layer files for the `# - Directly installable: <description>` marker and then *importing* the
  matched file path. That path-import approach is tied to the old bundle style; as layers move to
  `layers.<group>.<name>` namespaces the picker needs to switch to setting that option's `enable`
  instead.

---

## 9. Agent Guidelines

- **Never run `./clu build` or `./clu update`** directly. These commands invoke `nixos-rebuild` and
  make system-level changes (or trigger long Nix evaluations) that must be run explicitly by the
  user. Make config changes and explain what command the user should run to apply them.
- **Always use `rg` (ripgrep) instead of `grep`** for searching file contents.
- **When the user doesn't specify a host name** (e.g. "my config", "this machine"), run `hostname`
  and match it to the corresponding `hosts/<hostname>/` directory. That host's directory name
  matches the actual hostname of the box you're running on.

---

## 10. Build Flow Summary

`clu update workstation` ties §1/§2/§3 together in order:
1. `lib/flake` stages that one host's args (§2: decrypt, `git add -f`, set an `EXIT` trap)
2. `lib/update` runs `nixos-rebuild switch --flake "${CONFIG_DIR}#workstation"`
3. Nix evaluates `mkHost "workstation"` (§3's `mergeArgs`) then the host's `configuration.nix`
4. The `EXIT` trap fires: unstage and delete that host's decrypted args, regardless of success
