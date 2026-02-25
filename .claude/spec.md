# NixOS Configuration Repository Specification

## Context

This document is a reference specification describing the architecture and conventions of this NixOS
configuration repository. It is intended as context for future feature additions, not as an
implementation plan for a specific change.

---

## 1. Repository Overview

A multi-machine NixOS configuration managing 22+ physical and virtual machines through a custom bash
automation layer (`clu`) that orchestrates Nix flake evaluation. The key architectural distinction is
that **machine selection happens at the bash layer** via symlinks and file staging before Nix ever
evaluates, rather than through conventional per-host `nixosConfigurations.<hostname>` entries.

---

## 2. The `clu` Bash Framework

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
| `deploy` | `lib/deploy` | Copy repo to `/var/lib/vms/<machine>` and build VM |
| `run` | `lib/run` | Launch VMs with QEMU |
| `clean` | `lib/clean` | GC nix store, remove decrypted files, clean VMs |
| `list` | `lib/list` | List profiles, system generations |
| `init` | `lib/init` | Set up sops keys, git hooks, remotes |
| `dev` | `lib/dev` | Launch dev shells (e.g. gtk4) |
| `shell` | `lib/shell` | Wrapper around `nix-shell` |
| `repl` | `lib/repl` | Launch `nix repl` with machine's flake |
| `pkgs` | `lib/pkgs` | Package lookup via nix-index-database |
| `decrypt` | `lib/decrypt` | Decrypt all `*.enc.*` files |

### Core Utilities: `lib/utils`

- **Argument parsing**: `utils::process_args` extracts global flags (`--debug`, `--test`, `--clean`, `--impure`, `-q`, `-v`)
- **Root handling**: `utils::handle_root` sets `ROOT_DIR` ("" or "/mnt"), `CONFIG_DIR` (cwd,
/etc/nixos, or /mnt/etc/nixos), detects sudo context and drops privileges when appropriate
- **Config detection**: `utils::cwd_is_nixos_config` checks for `base.nix` + `base.lock`
- **Encryption**: `utils::decrypt` (sops `*.enc.*` -> `*.dec.*`), `utils::add_decrypted_to_git`, `utils::remove_decrypted`
- **Interactive I/O**: `utils::read`, `utils::select`, `utils::confirm_continue`
- **File editing**: `utils::replace` / `utils::update` for sed-based value substitution in config files

### Logging: `lib/log`

4-level system (error/warn/info/debug) controlled by `LOG_LEVEL`. ANSI color helpers. Formatted
headers and indented sub-logging.

---

## 3. The Machine-Linking Mechanism (`lib/flake`)

This is the most unconventional aspect of the repo. Instead of defining
`nixosConfigurations.<hostname>` for each machine, the flake defines a single generic entry:

```nix
nixosConfigurations.target = lib.nixosSystem {
  modules = [ ./options ./configuration.nix ];
};
```

**The `flake::switch(target)` function** (called before every build/update) makes the generic
`target` resolve to a specific machine:

1. **Flake files**: If `machines/<name>/flake.nix` exists, copies it to root. Otherwise copies
   `base.nix` -> `flake.nix` and `base.lock` -> `flake.lock`.
2. **Configuration symlink**: Creates `configuration.nix` -> `machines/<name>/configuration.nix`
   (relative symlink).
3. **Args update**: Writes `hostname` and `target` into `args.nix` so the Nix evaluation knows which
   machine it's building.
4. **Git staging**: `git add -f` all modified files so the flake can see them (Nix flakes only see
   tracked files).
5. **Decryption**: Decrypts `*.enc.*` files and stages the results.

**`flake::restore()`** reverses all of this after the build, returning the repo to a clean state. A
trap on EXIT ensures cleanup even on failure.

**`flake::stage_files(target)`** is the full workflow wrapper: removes `/nix/files.lock`, calls
`flake::switch`, sets the restore trap.

### Why This Matters for Feature Work

- All `nixos-rebuild` and `nix build` commands use `--flake "${CONFIG_DIR}#target"` - never a
  machine-specific configuration name.
- The `args.nix` file at root is **ephemeral** - it gets modified during builds and restored after.
  The real defaults live in the committed `args.nix`, with overrides in per-machine `args.nix` and
  encrypted `args.dec.json` files.
- Adding a new machine means creating a `machines/<name>/` directory, not touching `flake.nix`.

---

## 4. Flake Structure (`flake.nix`)

### Inputs
- `nixpkgs`: Pinned to a specific commit (currently 2025.08.09 unstable)
- `nixpkgs-unstable`: Follows `nixos-unstable` for bleeding-edge packages
- `nixpkgs-rustdesk`: Pinned older version for RustDesk compatibility

### Outputs
Three `nixosConfigurations`:
- **`target`**: Standard machine build. Imports `./options` + `./configuration.nix` (the symlink).
- **`install`**: Installation host. Imports `./hardware-configuration.nix` + the profile path from `args.target`.
- **`iso`**: ISO image build. Uses `profiles/iso_args.nix` to exclude secrets.

### Argument Composition (Priority Low -> High)
1. `args.nix` - Base defaults (committed)
2. `args.dec.json` - Base secrets (decrypted at build time)
3. `machines/<hostname>/args.nix` - Machine-specific overrides
4. `machines/<hostname>/args.dec.json` - Machine-specific secrets

Merged via `lib.recursiveUpdate` and passed as `specialArgs = { inherit args f inputs; }`.

### Overlays
Custom packages injected into the global `pkgs` namespace:
- **Custom builds**: `clu`, `arcologout`, `desktop-assets`, `rdutil`, `tinymediamanager`, `wmctl`
- **Unstable overrides**: `immich`, `vscode`, `zed-editor`, `zoom-us`, `rust-analyzer`,
  `synology-drive-client`, `tailscale`, `yt-dlp`

---

## 5. Directory Structure

```
/
├── clu                          # Bash entry point
├── lib/                         # Bash library modules (one per command)
├── flake.nix                    # Active flake (copied from base.nix or machine-specific)
├── base.nix                     # Canonical flake definition
├── base.lock / flake.lock       # Lock files
├── args.nix                     # Default arguments (modified ephemerally during builds)
├── args.enc.json                # Encrypted base secrets
├── configuration.nix            # SYMLINK to active machine's configuration.nix
├── options/                     # Custom NixOS option modules
│   ├── default.nix              # Imports all subdirectories
│   ├── apps/                    # Application options (games/, media/, network/, office/, system/)
│   ├── development/             # Dev tool options (claude-code/, rust, flutter, vscode, android, zed/)
│   ├── devices/                 # Hardware options (audio, bluetooth, boot, firmware, gpu, kernel, printers)
│   ├── files/                   # File management options
│   ├── networking.nix           # Global networking
│   ├── services/                # Service options (nspawn/, oci/, raw/)
│   ├── system/                  # System options (dconf, fonts, x11/, xfce/, xdg/)
│   ├── types/                   # Type definitions (machine.nix is the central hub)
│   └── virtualisation/          # VM options (podman, qemu/, virt-manager, winetricks)
├── profiles/                    # Composable configuration profiles
│   ├── core.nix                 # Minimal (bash, git, nix essentials)
│   ├── base.nix                 # CLI environment (core + locale, nix config, terminal, utils)
│   ├── iso.nix / iso_args.nix   # ISO build profile
│   └── xfce/                    # Desktop profiles
│       ├── base.nix             # XFCE minimal (X11, fonts, firefox, audio)
│       ├── desktop.nix          # Full desktop (base + media, games, office)
│       ├── develop.nix          # Development (desktop + rust, flutter, claude-code, vscode)
│       ├── laptop.nix           # Laptop-specific
│       └── theater.nix          # Media center
├── machines/                    # Per-machine configurations (22+ machines)
│   └── <name>/
│       ├── configuration.nix    # Machine config (imports hardware + profile)
│       ├── hardware-configuration.nix
│       ├── args.enc.json        # Machine secrets (encrypted)
│       ├── args.nix             # Machine arg overrides (optional)
│       ├── flake.nix/lock       # Machine-specific flake (optional, overrides base.nix)
│       └── README.md            # Machine documentation (optional)
├── modules/                     # Reusable NixOS modules
│   ├── development/vscode/      # VSCode settings, keybindings, extensions
│   ├── hardware/                # Apple hardware, scanners
│   ├── services/                # i3lock, smartd, systemd
│   ├── terminal/                # bash, env, git, starship
│   ├── locale.nix, nix.nix, users.nix
├── packages/                    # Custom package definitions
│   ├── arcologout/, desktop-assets/, kasmvnc/, rdutil/, selkies/, tinymediamanager/, wmctl/
├── funcs/                       # Nix helper functions (network.nix, service.nix)
└── .sops.yaml                   # Secrets management config (age encryption)
```

---

## 6. Option Architecture

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
- `apps.games.<name>.enable` - Games
- `apps.media.<name>.enable` - Media applications
- `apps.network.<name>.enable` - Network applications
- `apps.office.<name>.enable` - Office applications
- `apps.system.<name>.enable` - System utilities
- `development.<name>.enable` - Development tools
- `devices.<name>.enable` / `devices.<name>.<variant>` - Hardware
- `services.raw.<name>.enable` - Host services
- `services.oci.<name>.enable` - OCI container services
- `services.nspawn.<name>.enable` - nspawn container services
- `system.xfce.enable`, `system.x11.enable`, etc. - System components
- `virtualisation.<name>.enable` - Virtualization

### The `machine` Type (`options/types/machine.nix`)

Central hub defining all machine-level configuration. Every field defaults from the composed `args` attribute set:

- `machine.type.*` - Capability flags: `bootable`, `vm`, `iso`, `develop`, `theater`
- `machine.vm.type.*` - VM variants: `micro`, `local`, `spice`
- `machine.hostname`, `machine.id`, `machine.target`, `machine.efi`, `machine.mbr`, `machine.arch`
- `machine.locale`, `machine.timezone`, `machine.autologin`, `machine.bluetooth`, `machine.resolution`
- `machine.nix.*` - Nix config: `minVer`, `cache.enable/ip/port`
- `machine.git.*` - Git metadata: `user`, `email`, `comment`
- `machine.secrets` - List of `{name, value}` decrypted secrets
- `machine.net.*` - Full networking: `gateway`, `subnet`, `dns`, `bridge`, `macvlan`, `nic0`, `nic1`
- `machine.nfs.*` - NFS mounts: `enable`, `entries`
- `machine.smb.*` - Samba shares: `enable`, `user`, `pass`, `domain`, `entries`
- `machine.user.*` - User config: `name`, `pass`, `fullname`, `email`, `uid`, `gid`

---

## 7. Profile Composition

Profiles form an inheritance chain:

```
core.nix -> base.nix -> xfce/base.nix -> xfce/desktop.nix -> xfce/develop.nix
                                       -> xfce/laptop.nix
                                       -> xfce/theater.nix
```

Each profile layer adds:
- Package lists via `environment.systemPackages`
- Option enables (e.g. `apps.games.steam.enable = true`)
- Module imports (e.g. `../../modules/development/vscode`)
- Machine type flags (e.g. `machine.type.develop = true`)

Machine configs import exactly one profile and add machine-specific overrides.

---

## 8. Secrets Management

- **Tool**: sops with age encryption
- **Config**: `.sops.yaml` at repo root with age public key
- **Pattern**: `*.enc.json` (committed, encrypted) -> `*.dec.json` (ephemeral, decrypted at build time)
- **Lifecycle**: `utils::decrypt` decrypts before build, `utils::remove_decrypted` cleans up after
- **Git integration**: Decrypted files are `git add -f`'d temporarily, then unstaged on restore
- **ISO exclusion**: ISO builds use `profiles/iso_args.nix` instead of secrets

---

## 9. Conventions for Adding Features

### Adding a New Machine
1. Create `machines/<name>/` with `configuration.nix` and `hardware-configuration.nix`
2. The `configuration.nix` imports a profile and `./hardware-configuration.nix`
3. Add `args.enc.json` with machine-specific secrets (encrypt with sops)
4. Optionally add `args.nix` for non-secret overrides or `flake.nix`/`flake.lock` for pinned inputs

### Adding a New Option
1. Create `options/<category>/<name>.nix` (or `options/<category>/<name>/default.nix` for complex options)
2. Follow the `enable = lib.mkEnableOption` + `config = lib.mkIf` pattern
3. The option is auto-imported through the `options/default.nix` -> `options/<category>/default.nix` chain
4. Enable it in the appropriate profile or machine config

### Adding a New Package Overlay
1. Add to the `overlays` list in `flake.nix` / `base.nix`
2. For custom packages, create `packages/<name>/` with a `default.nix`
3. For options with custom builds, use `package.nix` in the option directory (not `default.nix`,
   which is reserved for the option definition)

### Adding a New Profile
1. Create `profiles/<name>.nix` or `profiles/<category>/<name>.nix`
2. Import a parent profile and add option enables / packages
3. Reference from machine configs via relative import

### Adding a New `clu` Command
1. Create `lib/<command>` with `<command>::run()` and `<command>::usage()` functions
2. Add `source` line in `lib/all`
3. Add case in `clu` main dispatch and usage text

---

## 10. Build Flow Summary

```
User runs: clu update workstation

1. lib/utils   -> parse args, detect root/config paths
2. lib/flake   -> flake::stage_files "machines/workstation"
   a. Copy base.nix -> flake.nix, base.lock -> flake.lock
   b. Symlink configuration.nix -> machines/workstation/configuration.nix
   c. Update args.nix with hostname="workstation", target="machines/workstation"
   d. Decrypt *.enc.* -> *.dec.*, git add all staged files
3. lib/update  -> sudo nixos-rebuild switch --flake "${CONFIG_DIR}#target"
4. Nix evaluates:
   a. flake.nix reads args.nix (hostname=workstation)
   b. Merges args: base -> base secrets -> machine args -> machine secrets
   c. Evaluates nixosConfigurations.target with ./options + ./configuration.nix (symlink)
   d. configuration.nix imports hardware config + profile
   e. Profile enables options, options produce NixOS config
5. lib/flake   -> flake::unstage_files (restore all files, touch files.lock)
```
