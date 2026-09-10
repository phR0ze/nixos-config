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

### Logging: `lib/log`

4-level system (error/warn/info/debug) controlled by `LOG_LEVEL`.

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
modules/               # All NixOS modules - opt-in feature namespaces AND always-on baseline (see §5)
layers/                # Composable configuration layers + bundles/ aggregators (see §6)
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

### The `host` Type (`modules/types/host.nix`)

Central hub defining all host-level configuration. Every field defaults from the composed `args`
attribute set (see §3). This is what lets layers/hosts stay DRY across 22+ hosts: shared layer
modules read `config.host.*` (populated per-host from `args.nix`/`args.enc.yaml`) to parameterize
real NixOS options (`users.users.*`, `networking.*`, `fileSystems.*`, ...) instead of every host
repeating that config directly. Representative fields: `host.type.*` (capability flags like `vm`,
`iso`, `develop`), `host.net.*` (networking), `host.secrets` (nullable path to that host's
`secrets.enc.yaml`) - see `modules/types/host.nix` for the full option set, it's the source of
truth and this list will go stale otherwise.

---

## 6. Layer Composition

Layers are atomic, standalone NixOS modules - no layer imports another layer (order-independent,
mixable, the way the module system is meant to be used). To avoid every one of 22+ hosts repeating
the same 4-5 item `imports` list for a common host class, thin **bundle** modules under
`layers/bundles/` aggregate the atomic layers a class needs - e.g. `bundles/xfce-desktop.nix` is
just `imports = [ core.nix base.nix xfce/base.nix xfce/desktop.nix ]`. See `layers/bundles/` for
the current set; each bundle file is short enough to read directly rather than needing a diagram
here.

Each layer adds:
- Package lists via `environment.systemPackages`
- Option enables (e.g. `apps.games.steam.enable = true`)
- Module imports of genuine always-on `modules/*` dependencies (e.g. `layers/console/core.nix` importing
  `../modules/system/users.nix` - see §5's "always-on baseline modules" category)
- Host type flags (e.g. `host.type.develop = true`)

A host's `configuration.nix` typically imports one bundle. For a one-off combination not covered by
an existing bundle, a host may instead hand-pick a flat list of atomic layers directly - Nix's module
system dedups imports by absolute file path, so mixing a bundle with an extra atomic layer is safe
and won't double-import anything.

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
working tree at all. `host.secrets` (user password hash, via `modules/users.nix`) and
`host.smb.secrets` (SMB share creds, via `modules/services/raw/smb`, using `sops.templates`) both
follow this pattern. Prefer this over the build-time-args mechanism whenever a value is only consumed
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

### Adding a New Layer or Bundle
Layers never import other layers - only genuine `modules/*` dependencies (§6). A new bundle needs
the `# - Directly installable: <description>` marker comment so `clu install`'s interactive picker
(`lib/install`) surfaces it. Mixing a bundle with an extra hand-picked atomic layer in a host's
`configuration.nix` is safe - Nix dedups imports by absolute file path.

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
