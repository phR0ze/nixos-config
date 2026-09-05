# NixOS Configuration Repository

A multi-host NixOS configuration managing 22+ physical and virtual hosts through a custom bash
automation layer (`clu`) that orchestrates Nix flake evaluation. Host selection is a real, standard
per-host `nixosConfigurations.<hostname>` flake entry, generated from each `hosts/<hostname>/`
directory. The one thing `clu` still has to stage before evaluation is each host's *build-time args*
(`hosts/<hostname>/args.enc.json`, decrypted to `args.dec.json`) - Nix flakes only see git-tracked
or staged files, and some of that data (drive UUIDs, network interface config, EFI/MBR selection) is
genuinely needed by NixOS module options at evaluation time, so it can't be deferred to sops-nix's
normal activation-time secret decryption. This staging is scoped to exactly one host per build and
reverted immediately after via a `trap ... EXIT`.

---

## 1. The `clu` Bash Framework

### Entry Point: `/clu`

The main CLI script. Sources `lib/all` which loads every module in `lib/`. Parses a command and
dispatches to `<command>::run()`.

### Key Commands

| Command | Lib File | Purpose |
|---------|----------|---------|
| `build` | `lib/build` | Dry-activate, build ISOs, build VMs |
| `update` | `lib/update` | Apply config changes via `nixos-rebuild switch` |
| `upgrade` | `lib/upgrade` | Update flake inputs + rebuild |
| `install` | `lib/install` | Interactive wizard: partition disk, generate hardware config, install NixOS |
| `switch` | `lib/switch` | Switch to a different NixOS generation (profile symlink manipulation) |
| `deploy` | `lib/deploy` | Copy repo to `/var/lib/vms/<host>` and build VM |
| `run` | `lib/run` | Launch VMs with QEMU |
| `clean` | `lib/clean` | GC nix store, remove decrypted files, clean VMs |
| `list` | `lib/list` | List layers, system generations |
| `init` | `lib/init` | Set up sops keys, git hooks, remotes |
| `dev` | `lib/dev` | Launch dev shells (e.g. gtk4) |
| `shell` | `lib/shell` | Wrapper around `nix-shell` |
| `repl` | `lib/repl` | Launch `nix repl` with host's flake |
| `pkgs` | `lib/pkgs` | Package lookup via nix-index-database |
| `decrypt` | `lib/decrypt` | Decrypt all `*.enc.*` files |
| `logs` | `lib/logs` | Print derivation build logs for packages |
| `manage` | `lib/manage` | Manage the clu repo (e.g. `repo` subcommand) |
| `registry` | `lib/registry` | Interact with Nix registry (e.g. `list` subcommand) |
| `test` | `lib/test` | Testing function for development |

### Core Utilities: `lib/utils`

- **Argument parsing**: `utils::process_args` extracts global flags (`--debug`, `--test`, `--clean`, `--impure`, `-q`, `-v`)
- **Root handling**: `utils::handle_root` sets `ROOT_DIR` ("" or "/mnt"), `CONFIG_DIR` (cwd,
/etc/nixos, or /mnt/etc/nixos), detects sudo context and drops privileges when appropriate
- **Config detection**: `utils::cwd_is_nixos_config` checks for `flake.nix` + `args.nix`
- **Encryption**: `utils::decrypt` (sops `*.enc.*` -> `*.dec.*`, recursive - used by `clu decrypt`/`clu clean dec` for manual/broad cleanup), `utils::add_decrypted_to_git`, `utils::remove_decrypted`
- **Interactive I/O**: `utils::read`, `utils::select`, `utils::confirm_continue`
- **File editing**: `utils::replace` / `utils::update` for sed-based value substitution in config files

### Logging: `lib/log`

4-level system (error/warn/info/debug) controlled by `LOG_LEVEL`. ANSI color helpers. Formatted
headers and indented sub-logging.

---

## 2. Host Selection & Build-Time Args (`lib/flake`)

The flake generates one real entry per host directory:

```nix
hostNames = builtins.attrNames (lib.filterAttrs (n: v: v == "directory") (builtins.readDir ./hosts));
nixosConfigurations = lib.genAttrs hostNames mkHost // { install = ...; iso = ...; };
```

`mkHost hostname` builds `lib.nixosSystem { modules = [ ... (./hosts + "/${hostname}/configuration.nix") ]; }`
directly - there's no symlink or per-invocation file copying involved in selecting a host.
`nixosConfigurations` is a lazy attrset, so `nix build .#<hostname>...` only forces evaluation of that
one host; every other (still-encrypted) host's args are never touched.

**What still needs staging**: `hosts/<hostname>/args.dec.json` and root `args.dec.json` - the
decrypted forms of `args.enc.json`. Some of that data (drive UUIDs, network config, EFI/MBR) is
consumed by NixOS module options at evaluation time, and Nix flakes only see git-tracked/staged files,
so there's no way around staging without `--impure` (deliberately avoided - see §7).

**The `flake::switch(target)` function** (called before every build/update), for a `hosts/*`
target:
1. Runs `flake::decrypt_args(hostname)`: `sops --decrypt` on root `args.enc.json` and
   `hosts/<hostname>/args.enc.json` (whichever exist) to `args.dec.json` siblings, then
   `git add -f`s them.
2. Remembers the hostname in `_FLAKE_ARGS_HOST` so `flake::restore` knows what to clean up, without
   depending on the format of whatever the caller's `$MACHINE`/`$TARGET` variables happen to be.

Layer-only targets (`layers/*`, e.g. ISO builds) skip this entirely - there's no per-host args to
decrypt, and ISO builds deliberately exclude secrets (`layers/iso_args.nix`).

**`flake::restore()`** unstages and deletes the one host's `args.dec.json` files. A `trap ...  EXIT`
in every caller ensures this runs even on failure, so a crash leaves at most one host's plaintext
behind (`clu clean dec` sweeps up any leftovers via the broader `utils::remove_decrypted`).

**`flake::stage_files(target)`** is the full workflow wrapper: removes `/nix/files.lock`, calls
`flake::switch`, sets the restore trap.

### Why This Matters for Feature Work

- All `nixos-rebuild`/`nix build`/`nixos-install` commands use `--flake "${CONFIG_DIR}#${MACHINE}"`
  (the real hostname), not a generic `#target` name.
- `args.nix` at root is a normal, permanently committed file now - nothing mutates it per build.
  `hostname` and `git.comment` in the final merged `args` are always set authoritatively by
  `flake.nix` itself (from the `hosts/` directory name and `self.rev`, respectively), never read
  from a file, so they can't drift.
- Adding a new host means creating a `hosts/<name>/` directory - nothing else to touch.

---

## 3. Flake Structure (`flake.nix`)

There is exactly one `flake.nix` (and `flake.lock`), permanently committed at the repo root - no more
`base.nix`/per-machine `flake.nix` copy-swapping. Only `macbook` needs an extra input
(`nixos-hardware`, for the `apple-t2` module); since flake inputs can't be conditional on which host
is being built, it's declared unconditionally and only referenced by `mkHost` when `hostname ==
"macbook"`.

### Inputs
- `nixpkgs`: Pinned to a specific commit (currently 2025.08.09 unstable)
- `nixpkgs-unstable`: Follows `nixos-unstable` for bleeding-edge packages
- `nixos-hardware`: Only used by macbook (`apple-t2` module)

### Outputs
- **`nixosConfigurations.<hostname>`**: One real entry per `hosts/<hostname>/` directory, built by
  `mkHost hostname`. Imports `./options` + `hosts/<hostname>/configuration.nix` directly.
- **`install`**: Bootstrap host used before a host has its own `hosts/<hostname>` directory yet.
  Imports `./hardware-configuration.nix` + the layer/bundle path from `args.target`.
- **`iso`**: ISO image build. Uses `layers/iso_args.nix` to exclude secrets.

### Argument Composition (Priority Low -> High)
`mergeArgs hostname` in `flake.nix`:
1. `args.nix` - Base defaults (committed)
2. `args.dec.json` - Base secrets (decrypted at build time)
3. `hosts/<hostname>/args.nix` - Host-specific overrides
4. `hosts/<hostname>/args.dec.json` - Host-specific secrets
5. `hostname` and `git.comment` are then always set authoritatively (directory name / `self.rev`),
   overriding anything the above files might otherwise supply

Merged via `lib.recursiveUpdate` (careful: a plain `//` at the top level would silently clobber
nested attrsets like `git.*` - always use `lib.recursiveUpdate` when overriding a leaf) and passed as
`specialArgs = { inherit args f inputs; }`, computed once per host inside `mkHost`.

### Overlays
Custom packages injected into the global `pkgs` namespace:
- **Custom builds**: `clu`, `arcologout`, `desktop-assets`, `rdutil`, `tinymediamanager`, `wmctl`
- **Unstable overrides**: `immich`, `vscode`, `zed-editor`, `zoom-us`, `rust-analyzer`,
  `synology-drive-client`, `tailscale`, `yt-dlp`

---

## 4. Directory Structure

```
/
├── clu                          # Bash entry point
├── lib/                         # Bash library modules (one per command)
├── flake.nix / flake.lock       # The single shared flake (permanently committed)
├── args.nix                     # Default arguments (static, committed - never mutated by clu)
├── args.enc.json                # Encrypted base secrets
├── hardware-configuration.nix   # Gitignored placeholder, only present during clu install
├── options/                     # Custom NixOS option modules
│   ├── default.nix              # Imports all subdirectories
│   ├── apps/                    # Application options (dev/, games/, media/, network/, office/, system/)
│   │   ├── dev/                 # Dev tool options (android/, claude/, flutter/, gemini/, gh/, rust/, vscode/, zed/)
│   │   └── system/              # System utilities (clu/, flatpak/, ghostty/, neovide/, neovim/, veracrypt/, wezterm/)
│   ├── devices/                 # Hardware options (audio, bluetooth, boot, firmware, gpu, kernel, printers)
│   ├── files/                   # File management options
│   ├── networking.nix           # Global networking
│   ├── services/                # Service options (nspawn/, oci/, raw/)
│   ├── system/                  # System options (dconf, fonts, x11/, xfce/, xdg/)
│   ├── types/                   # Type definitions (host.nix is the central hub)
│   └── virtualisation/          # VM options (podman, qemu/, virt-manager, winetricks)
├── layers/                      # Composable configuration layers
│   ├── core.nix                 # ATOMIC: minimal (bash, git, nix essentials)
│   ├── base.nix                 # ATOMIC: CLI environment (locale, nix config, terminal, utils)
│   ├── iso.nix / iso_args.nix   # ISO build layer
│   ├── budgie/base.nix          # ATOMIC: Budgie with LightDM
│   ├── plasma/base.nix          # ATOMIC: Plasma 6 with SDDM and Wayland
│   ├── xfce/
│   │   ├── base.nix             # ATOMIC: XFCE minimal (X11, fonts, firefox, audio)
│   │   ├── desktop.nix          # ATOMIC: full desktop (media, games, office)
│   │   ├── develop.nix          # ATOMIC: development (rust, flutter, claude, vscode)
│   │   ├── laptop.nix           # ATOMIC: laptop-specific
│   │   └── theater.nix          # ATOMIC: media center
│   └── bundles/                 # Thin aggregators: imports-only lists of atomic layers
│       ├── xfce-desktop.nix     # core + base + xfce/base + xfce/desktop
│       ├── xfce-develop.nix     # + xfce/develop
│       ├── xfce-laptop.nix      # + xfce/laptop
│       ├── xfce-theater.nix     # + xfce/theater
│       ├── budgie-desktop.nix   # core + base + budgie/base
│       └── plasma-desktop.nix   # core + base + plasma/base
├── hosts/                       # Per-host configurations (22+ hosts)
│   └── <name>/
│       ├── configuration.nix    # Host config (imports hardware + a layer bundle)
│       ├── hardware-configuration.nix
│       ├── args.enc.json        # Host secrets (encrypted)
│       ├── args.nix             # Host arg overrides (optional)
│       ├── secrets.enc.yaml     # Runtime secrets, decrypted by sops-nix at activation (optional)
│       └── README.md            # Host documentation (optional)
├── modules/                     # Reusable NixOS modules
│   ├── development/vscode/      # VSCode settings, keybindings, extensions
│   ├── hardware/                # Apple hardware, scanners
│   ├── services/                # i3lock, smartd, systemd
│   ├── terminal/                # bash, env, git, starship
│   ├── locale.nix, nix.nix, users.nix
├── include/                     # Static file templates
│   ├── home/                    # User home directory templates (config, dircolors, face)
│   ├── usr/share/fonts/TTF/     # Custom TTF fonts
│   └── var/lib/nix-cache/       # Nix cache keys
├── packages/                    # Custom package definitions
│   ├── arcologout/, desktop-assets/, kasmvnc/, rdutil/, selkies/, tinymediamanager/, wmctl/
├── funcs/                       # Nix helper functions (network.nix, service.nix)
└── .sops.yaml                   # Secrets management config (age encryption)
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

### Option Namespaces
- `apps.dev.<name>.enable` - Development tools (claude, gemini, gh, rust, flutter, vscode, android, zed)
- `apps.games.<name>.enable` - Games
- `apps.media.<name>.enable` - Media applications
- `apps.network.<name>.enable` - Network applications
- `apps.office.<name>.enable` - Office applications
- `apps.system.<name>.enable` - System utilities (clu, flatpak, ghostty, neovide, neovim, veracrypt, wezterm)
- `devices.<name>.enable` / `devices.<name>.<variant>` - Hardware (audio, bluetooth, boot, firmware, gpu, kernel, printers)
- `services.raw.<name>.enable` - Host services
- `services.oci.<name>.enable` - OCI container services
- `services.nspawn.<name>.enable` - nspawn container services
- `system.xfce.enable`, `system.x11.enable`, etc. - System components
- `virtualisation.<name>.enable` - Virtualization

### The `host` Type (`options/types/host.nix`)

Central hub defining all host-level configuration. Every field defaults from the composed `args` attribute set. This is what lets layers/hosts stay DRY across 22+ hosts: shared layer modules read `config.host.*` (populated per-host from `args.nix`/`args.enc.json`) to parameterize real NixOS options (`users.users.*`, `networking.*`, `fileSystems.*`, ...) instead of every host repeating that config directly:

- `host.type.*` - Capability flags: `bootable`, `vm`, `iso`, `develop`, `theater`
- `host.vm.type.*` - VM variants: `micro`, `local`, `spice`
- `host.hostname`, `host.id`, `host.target`, `host.efi`, `host.mbr`, `host.arch`
- `host.locale`, `host.timezone`, `host.autologin`, `host.bluetooth`, `host.resolution`
- `host.nix.*` - Nix config: `minVer`, `cache.enable/ip/port`
- `host.git.*` - Git metadata: `user`, `email`, `comment`
- `host.secrets` - List of `{name, value}` decrypted secrets
- `host.net.*` - Full networking: `gateway`, `subnet`, `dns`, `bridge`, `macvlan`, `nic0`, `nic1`
- `host.nfs.*` - NFS mounts: `enable`, `entries`
- `host.smb.*` - Samba shares: `enable`, `user`, `pass`, `domain`, `entries`
- `host.user.*` - User config: `name`, `pass`, `fullname`, `email`, `uid`, `gid`

---

## 6. Layer Composition

Layers are atomic, standalone NixOS modules - no layer imports another layer (order-independent,
mixable, the way the module system is meant to be used). To avoid every one of 22+ hosts repeating
the same 4-5 item `imports` list for a common host class, thin **bundle** modules under
`layers/bundles/` aggregate the atomic layers a class needs:

```
Atomic layers (never import each other):
  core.nix, base.nix, budgie/base.nix, plasma/base.nix,
  xfce/{base,desktop,develop,laptop,theater}.nix

Bundles (imports-only aggregators, one per host class):
  bundles/xfce-desktop.nix  = core + base + xfce/base + xfce/desktop
  bundles/xfce-develop.nix  = xfce-desktop + xfce/develop
  bundles/xfce-laptop.nix   = xfce-desktop + xfce/laptop
  bundles/xfce-theater.nix  = xfce-desktop + xfce/theater
  bundles/budgie-desktop.nix = core + base + budgie/base
  bundles/plasma-desktop.nix = core + base + plasma/base
```

Each layer adds:
- Package lists via `environment.systemPackages`
- Option enables (e.g. `apps.games.steam.enable = true`)
- Module imports of genuine `modules/*` dependencies (e.g. `../../modules/development/vscode`)
- Host type flags (e.g. `host.type.develop = true`)

A host's `configuration.nix` typically imports one bundle. For a one-off combination not covered by
an existing bundle, a host may instead hand-pick a flat list of atomic layers directly - Nix's module
system dedups imports by absolute file path, so mixing a bundle with an extra atomic layer is safe
and won't double-import anything.

---

## 7. Secrets Management

Two distinct mechanisms exist, used for two genuinely different needs - don't conflate them:

**Build-time args** (`args.enc.json` -> `args.dec.json`, used for data a NixOS module option needs
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
`host.smb.secrets` (SMB share creds, via `options/services/raw/smb`, using `sops.templates`) both
follow this pattern. Prefer this over the build-time-args mechanism whenever a value is only consumed
by a running service reading a file, not by a NixOS module option at evaluation time.

---

## 8. Conventions for Adding Features

### Adding a New Host
1. Create `hosts/<name>/` with `configuration.nix` and `hardware-configuration.nix` - `<name>`
   becomes the real `nixosConfigurations.<name>` flake attribute automatically, nothing else to
   register
2. The `configuration.nix` imports a bundle (or hand-picked atomic layers) and `./hardware-configuration.nix`
3. Add `args.enc.json` with host-specific build-time args that a module option needs at
   evaluation time (encrypt with sops); add `secrets.enc.yaml` for runtime-only credentials instead
4. Optionally add `args.nix` for non-secret overrides
5. If the host needs a flake input no other host uses, add it unconditionally to the root
   `flake.nix` and reference it conditionally in `mkHost` (see how `macbook`/`nixos-hardware` do it)

### Adding a New Option
1. Create `options/<category>/<name>.nix` (or `options/<category>/<name>/default.nix` for complex options)
2. Follow the `enable = lib.mkEnableOption` + `config = lib.mkIf` pattern
3. The option is auto-imported through the `options/default.nix` -> `options/<category>/default.nix` chain
4. Enable it in the appropriate layer or host config

### Adding a New Package Overlay
1. Add to the `overlays` list in `flake.nix`
2. For custom packages, create `packages/<name>/` with a `default.nix`
3. For options with custom builds, use `package.nix` in the option directory (not `default.nix`,
   which is reserved for the option definition)

### Adding a New Layer
1. Create `layers/<name>.nix` or `layers/<category>/<name>.nix` as a standalone module - don't import
   other layers from it; only genuine `modules/*` dependencies
2. Add option enables / packages
3. If it joins an existing host class, add it to (or create) a `layers/bundles/<class>.nix`
   aggregator; otherwise reference it directly from a host's `configuration.nix`

### Adding a New Bundle
1. Create `layers/bundles/<desktop-env>-<class>.nix` whose body is only an `imports` list of the
   atomic layers that class needs (see existing bundles for the pattern)
2. Add the `# - Directly installable: <description>` marker comment so `clu install`'s interactive
   picker (`lib/install`) surfaces it
3. Reference it from any host's `configuration.nix` that belongs to that class

### Adding a New `clu` Command
1. Create `lib/<command>` with `<command>::run()` and `<command>::usage()` functions
2. Add `source` line in `lib/all`
3. Add case in `clu` main dispatch and usage text

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

```
User runs: clu update workstation

1. lib/utils   -> parse args, detect root/config paths
2. lib/flake   -> flake::stage_files "hosts/workstation"
   a. Remove /nix/files.lock to permit a files/secrets update
   b. flake::switch "hosts/workstation":
      - Decrypt root args.enc.json -> args.dec.json and hosts/workstation/args.enc.json ->
        hosts/workstation/args.dec.json, git add -f both
      - Remember "workstation" in _FLAKE_ARGS_HOST for cleanup
   c. trap flake::unstage_files EXIT
3. lib/update  -> sudo nixos-rebuild switch --flake "${CONFIG_DIR}#workstation"
4. Nix evaluates:
   a. flake.nix's mkHost "workstation" computes mergeArgs "workstation": args.nix -> args.dec.json ->
      hosts/workstation/args.nix -> hosts/workstation/args.dec.json, then overrides
      hostname="workstation" and git.comment=self.rev authoritatively
   b. Evaluates nixosConfigurations.workstation with ./options + hosts/workstation/configuration.nix
   c. configuration.nix imports hardware config + a layer bundle
   d. The bundle's layers enable options, options produce NixOS config
5. lib/flake   -> flake::unstage_files -> flake::restore (unstage + rm the two args.dec.json files),
   touch /nix/files.lock
```
