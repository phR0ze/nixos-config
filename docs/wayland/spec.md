# Wayland Migration Specification

## 1. Overview and Goals

This document specifies the work needed to make this NixOS configuration capable of deploying either
an X11-based or Wayland-based desktop from a single codebase. The migration is **strictly additive**
— all existing XFCE configurations remain unchanged. A full parallel `profiles/plasma/` chain will
mirror the `profiles/xfce/` hierarchy. A machine switches display server by changing one `import`
line.

**X11 target**: XFCE + LightDM + Xfwm4 (current — unchanged)  
**Wayland target**: KDE Plasma 6 + SDDM (Wayland mode) + KWin  
**XWayland**: Enabled on all Wayland machines to support X11-only apps

---

## 2. Architectural Decisions

### 2.1 New Option Namespaces

Two new option modules mirror the existing `system.x11.*` / `system.xfce.*` hierarchy:

```
options/system/
├── x11/          (exists — unchanged)
│   ├── default.nix
│   └── xft.nix
├── xfce/         (exists — unchanged)
├── wayland/      (NEW) — system.wayland.enable
│   └── default.nix
└── plasma/       (NEW) — system.plasma.enable
    └── default.nix
```

### 2.2 Profile Structure

Full parallel `profiles/plasma/` chain:

```
profiles/
├── xfce/
│   ├── base.nix      (unchanged)
│   ├── desktop.nix   (unchanged)
│   ├── develop.nix   (unchanged)
│   ├── laptop.nix    (unchanged)
│   └── theater.nix   (unchanged)
└── plasma/
    ├── base.nix      (exists — major rewrite)
    ├── desktop.nix   (NEW)
    ├── develop.nix   (NEW)
    ├── laptop.nix    (NEW)
    └── theater.nix   (NEW)
```

### 2.3 X11-Only Apps: XWayland Fallback

The following apps have no Wayland-native equivalent and will run under XWayland on Plasma machines
without replacement:

| App | Reason |
|-----|--------|
| `simplescreenrecorder` | Captures X11 composited display |
| `galculator` | GTK2, no Wayland port |
| `tinymediamanager` | Java AWT/Swing |
| `xnviewmp` | Proprietary Qt5, no Wayland support |
| `xchm` | wxWidgets, X11-focused |
| `wine` / `winetricks` | Inherently requires X11 or XWayland |
| `gimp` (2.x) | GTK2; GIMP 3 would be native |
| `audacity` | Experimental Wayland support |
| `conky` | Limited Wayland support |
| `RustDesk` | Linux client is X11-only upstream |

`kdePackages.spectacle` is added to Plasma profiles as the primary screen capture tool (native
Wayland via PipeWire portal), with `simplescreenrecorder` available via XWayland for complex
recording needs.

### 2.4 Remote Desktop

| Session | Tool |
|---------|------|
| X11/XFCE | `x11vnc` + `rustdesk-flutter` (unchanged) |
| Wayland/Plasma | `rustdesk-flutter` only (VNC removed) |

### 2.5 Window Management (`wmctl`)

The custom `wmctl` Rust package (X11 EWMH) must be extended with a KWin D-Bus backend. It should
detect `WAYLAND_DISPLAY` at runtime and dispatch to the appropriate implementation. Until the Wayland
backend is complete, `wmctl` is excluded from Plasma profiles.

### 2.6 Clipboard

| Session         | Tool |
|-----------------|------|
| X11/XFCE        | `xclip` (installed via `system.x11.enable`) |
| Wayland/Plasma  | `wl-clipboard` (installed via `system.wayland.enable`) |

Neovim auto-detects `wl-copy`/`wl-paste` when available — no neovim config changes needed.

### 2.7 Theming Approach

The `system.x11.xft.*` option declarations remain in place and are reused by the Plasma option module
for font/DPI settings. Since these are pure option declarations (no X11 runtime dependency), they are
safe to reference from `system.plasma` even when `system.x11.enable = false`.

KDE Plasma manages Qt6 theming natively. Qt5 apps under Plasma still use
`libsForQt5.qtstyleplugin-kvantum` for Kvantum theming. The `qt.platformTheme = "qt5ct"` assignment
from `xsettings.nix` is XFCE-specific and must not be set on Plasma machines.

---

## 3. Step-by-Step Implementation Plan

### Step 1 — Create `options/system/wayland/default.nix`

**New file.** Analogous to `options/system/x11/default.nix`. Sets up SDDM, XWayland, libinput, and
the critical Wayland environment variables.

```nix
{ config, lib, pkgs, ... }:
let
  machine = config.machine;
  cfg = config.system.wayland;
in {
  options.system.wayland = {
    enable = lib.mkEnableOption "Enable Wayland display server";
  };

  config = lib.mkIf cfg.enable {
    system.xdg.enable = true;

    # XWayland — required for X11-only apps running under Wayland
    programs.xwayland.enable = true;

    services = {
      displayManager = {
        autoLogin.enable = machine.autologin;
        autoLogin.user = machine.user.name;
        sddm = {
          enable = true;
          wayland.enable = true;
        };
      };
      libinput = {
        enable = true;
        mouse.accelSpeed = "0.6";
        touchpad = {
          accelSpeed = "1";
          naturalScrolling = true;
        };
      };
    };

    # Wayland environment variables
    environment.sessionVariables = {
      NIXOS_OZONE_WL     = "1";             # Electron: activate Ozone Wayland
      GDK_BACKEND        = "wayland,x11";   # GTK: prefer Wayland, fall back to X11
      QT_QPA_PLATFORM    = "wayland;xcb";   # Qt: prefer Wayland, fall back to X11
      MOZ_ENABLE_WAYLAND = "1";             # Firefox: native Wayland
      SDL_VIDEODRIVER    = "wayland";       # SDL apps
      CLUTTER_BACKEND    = "wayland";       # Clutter apps
    };

    environment.systemPackages = with pkgs; [
      wl-clipboard      # wl-copy / wl-paste (replaces xclip)
      xdg-utils         # xdg-open, xdg-mime etc.
      # Themes (shared with X11)
      arc-theme
      arc-kde-theme
      paper-icon-theme
      numix-cursor-theme
    ];
  };
}
```

**Also update**: `options/system/default.nix` — add `./wayland` to the imports list.

---

### Step 2 — Create `options/system/plasma/default.nix`

**New file.** Analogous to `options/system/xfce/default.nix`. Enables Plasma 6, SDDM, and
Plasma-specific theming. Enabling this option implies `system.wayland.enable = true`.

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.system.plasma;
  xft = config.system.x11.xft;   # reuse font/DPI settings declared in xft.nix
  machine = config.machine;
in {
  options.system.plasma = {
    enable = lib.mkEnableOption "Enable KDE Plasma 6 desktop";
    panel.launchers = lib.mkOption {
      description = "Application launchers pinned to the Plasma taskbar";
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption { type = lib.types.str; };
          exec = lib.mkOption { type = lib.types.str; };
          icon = lib.mkOption { type = lib.types.str; default = ""; };
        };
      });
      default = [];
    };
    desktop.background = lib.mkOption {
      description = "Path to the desktop wallpaper image";
      type = lib.types.str;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    system.wayland.enable = true;           # Plasma always implies Wayland
    services.desktopManager.plasma6.enable = true;
    services.displayManager.defaultSession = "plasma";

    # GTK app theming under Plasma (handled by kde-gtk-config)
    programs.dconf.enable = true;

    # Qt5 theming for non-KDE Qt5 apps (Plasma handles Qt6 natively)
    environment.systemPackages = with pkgs; [
      libsForQt5.qtstyleplugin-kvantum
    ];

    # Kvantum theme for Qt5 apps
    files.all.".config/Kvantum/kvantum.kvconfig".text =
      "[General]\ntheme=${xft.qtTheme}";
    files.all.".config/Kvantum/ArcDark".link =
      ../../../include/home/.config/Kvantum/ArcDark;
  };
}
```

**Also update**: `options/system/default.nix` — add `./plasma` to the imports list.

---

### Step 3 — Rewrite `profiles/plasma/base.nix`

**Existing file — major changes.** Replace the `system.x11.enable = true` +
`lib.mkForce false` LightDM workaround with clean `system.plasma.enable = true`. Remove `wmctl`
pending the Wayland backend (Step 8). Add `kdePackages.spectacle`.

Key changes from the current file:

| Remove | Add |
|--------|-----|
| `system.x11.enable = true` | `system.plasma.enable = true` |
| `services.xserver.displayManager.lightdm.enable = lib.mkForce false` | (handled by `system.plasma.enable`) |
| `services.displayManager.sddm = { ... }` | (handled by `system.wayland.enable`) |
| `services.desktopManager.plasma6.enable = true` | (handled by `system.plasma.enable`) |
| `wmctl` from `environment.systemPackages` | (pending Wayland backend — Step 8) |
| | `kdePackages.spectacle` |
| | `services.gnome.gnome-keyring.enable = true` |
| | `security.pam.services.sddm.enableGnomeKeyring = true` |

Keep `kdePackages.xwaylandvideobridge` (already present).

---

### Step 4 — Patch `options/apps/media/obs/default.nix`

Add `obs-xdg-portal` when Wayland is active, enabling PipeWire-based screen capture:

```nix
plugins = with pkgs.obs-studio-plugins; [
  obs-backgroundremoval
  obs-pipewire-audio-capture
]
++ lib.optionals cfg.ndi [ obs-ndi ]
++ lib.optionals config.system.wayland.enable [ obs-xdg-portal ];
```

---

### Step 5 — Patch `options/services/raw/rustdesk.nix`

Guard the X11-only `xf86videodummy` package (used for headless Linux mode) behind a session check:

```nix
environment.systemPackages = [
  pkgs.rdutil
  pkgs.rustdesk-flutter
] ++ lib.optionals (!config.system.wayland.enable) [
  pkgs.xorg.xf86videodummy     # X11 headless support; not used on Wayland
];
```

---

### Step 6 — Patch `options/apps/games/steam/default.nix`

The `system.xdg.menu.itemOverrides` call is XFCE-specific. On Plasma, Kickoff handles Steam natively.
Guard it so it only applies on XFCE machines:

```nix
system.xdg.menu.itemOverrides = lib.mkIf config.system.xfce.enable [
  { categories = "Games"; source = "${package}/share/applications/steam.desktop"; }
];
```

---

### Step 7 — Patch `options/services/raw/x11vnc.nix`

Add a build-time assertion preventing `x11vnc` from being enabled on Wayland machines:

```nix
assertions = [{
  assertion = !config.system.wayland.enable;
  message = ''
    services.raw.x11vnc is incompatible with Wayland.
    Use RustDesk for remote access on Wayland/Plasma machines.
  '';
}];
```

---

### Step 8 — Extend `packages/wmctl/` with KWin D-Bus backend

The `wmctl` Rust binary performs X11 EWMH window management. A Wayland backend must be added using
KWin's `org.kde.KWin` D-Bus interface.

**Implementation approach**:

- Detect session type at runtime via `WAYLAND_DISPLAY` or `XDG_SESSION_TYPE`
- X11 path: existing EWMH implementation (unchanged)
- Wayland/KWin path: use the `zbus` crate to call KWin D-Bus APIs:
  - Window listing: `org.kde.KWin.getWindowInfo`
  - Window focus: `org.kde.KWin.Window` interface
  - Window manipulation: KWin scripting via `org.kde.kwin.Scripting`

**Deliverable**: Updated `packages/wmctl/` with `--backend [x11|kwin|auto]` flag (defaulting to
`auto`). After testing on a Plasma machine, re-add `wmctl` to `profiles/plasma/base.nix`.

---

### Step 9 — Create `profiles/plasma/desktop.nix`

**New file.** Mirrors `profiles/xfce/desktop.nix`. Imports `profiles/plasma/base.nix`.

Differences from `xfce/desktop.nix`:

- `system.xdg.menu.itemOverrides` blocks are omitted (XFCE-specific; Plasma manages menus natively)
- `services.raw.x11vnc` is not enabled (remote access is RustDesk only)
- `apps.network.rustdesk.enable = true` is included
- `simplescreenrecorder` stays (runs via XWayland)
- All media, games, and office packages are identical

---

### Step 10 — Create `profiles/plasma/develop.nix`

**New file.** Mirrors `profiles/xfce/develop.nix`. Imports `profiles/plasma/desktop.nix`.

The package set is identical. VSCode Wayland mode is handled by `NIXOS_OZONE_WL=1` set globally in
Step 1 — no changes to `apps.dev.vscode` needed.

```nix
{ pkgs, ... }:
{
  imports = [
    ./desktop.nix
    ../../modules/development/vscode
  ];

  machine.type.develop = true;
  apps.dev.gh.enable = true;
  apps.dev.rust.enable = true;
  apps.dev.flutter.enable = true;

  environment.systemPackages = with pkgs; [
    chromium          # Wayland-native via NIXOS_OZONE_WL=1
    google-cloud-sdk
    sqlitebrowser
    go
    go-bindata
    golangci-lint
    python3
  ];
}
```

---

### Step 11 — Create `profiles/plasma/theater.nix`

**New file.** Mirrors `profiles/xfce/theater.nix`. Imports `profiles/plasma/desktop.nix`.

Differences from `xfce/theater.nix`:

| XFCE Setting | Plasma Equivalent |
|---|---|
| `system.x11.xft.dpi = 120` | `environment.sessionVariables.QT_SCALE_FACTOR = "1.25"` + `GDK_SCALE = "1.25"` |
| `system.xfce.panel.taskbar.size = 36` | `system.plasma.panel.*` (from Step 2) |
| `system.xfce.displays.connectingDisplay = 0` | KDE Display Configuration |
| `system.xfce.desktop.background = "..."` | `system.plasma.desktop.background = "..."` |

---

### Step 12 — Create `profiles/plasma/laptop.nix`

**New file.** Mirrors `profiles/xfce/laptop.nix`. Imports `profiles/plasma/desktop.nix`.

```nix
{ ... }:
{
  imports = [ ./desktop.nix ];
  apps.network.rustdesk.autostart = false;
}
```

---

### Step 13 — Validate on `vm-test`

Update `machines/vm-test/configuration.nix` to import `profiles/plasma/desktop.nix`, build, and
boot:

```bash
clu build vm-test
clu run vm-test
```

Validation checklist:

- [ ] SDDM Wayland mode launches
- [ ] KDE Plasma 6 desktop loads
- [ ] `wl-copy`/`wl-paste` work in terminal and neovim
- [ ] Firefox reports Wayland native in `about:support` → Graphics
- [ ] VSCode uses Ozone Wayland (verify `WAYLAND_DISPLAY` is set in its process)
- [ ] OBS screen capture works via PipeWire portal
- [ ] Steam launches (via XWayland)
- [ ] `simplescreenrecorder` launches (via XWayland)
- [ ] RustDesk connects and accepts sessions
- [ ] Gnome Keyring unlocks on SDDM login (VPN / Copilot auth)
- [ ] Qt5 apps use Kvantum theme (check `smplayer`, `audacious`)

---

## 4. Complete App Compatibility Table

| App | XFCE/X11 | Plasma/Wayland | Notes |
|-----|:---:|:---:|-------|
| Firefox | ✓ | ✓ | `MOZ_ENABLE_WAYLAND=1` via global env |
| VSCode | ✓ | ✓ | `NIXOS_OZONE_WL=1` via global env |
| Chromium | ✓ | ✓ | `NIXOS_OZONE_WL=1` via global env |
| Zoom | ✓ | ✓ (XWayland) | No explicit Wayland flags configured |
| wezterm | ✓ | ✓ | Native Wayland backend (winit) |
| ghostty | ✓ | ✓ | GTK4 native Wayland |
| zed-editor | ✓ | ✓ | GPUI native Wayland |
| neovide | ✓ | ✓ | winit native Wayland |
| keepassxc | ✓ | ✓ | Qt native Wayland |
| mpv | ✓ | ✓ | `--vo=gpu,wayland` |
| vlc | ✓ | ✓ | Wayland backend available |
| smplayer | ✓ | ✓ | Qt; `QT_QPA_PLATFORM=wayland` via global env |
| qview | ✓ | ✓ | Qt Wayland |
| qbittorrent | ✓ | ✓ | Qt Wayland |
| OBS | ✓ | ✓ | + `obs-xdg-portal` for PipeWire capture (Step 4) |
| kdePackages.spectacle | — | ✓ | Plasma-native screen capture |
| kdePackages.xwaylandvideobridge | — | ✓ | Screen sharing via XWayland bridge |
| libreoffice-fresh | ✓ | ✓ | GTK3 Wayland support |
| handbrake | ✓ | ✓ | GTK3 Wayland |
| mkvtoolnix | ✓ | ✓ | Qt Wayland |
| losslesscut-bin | ✓ | ✓ | Electron; `NIXOS_OZONE_WL=1` |
| freetube | ✓ | ✓ | Electron; `NIXOS_OZONE_WL=1` |
| vdhcoapp | ✓ | ✓ | Electron; `NIXOS_OZONE_WL=1` |
| prismlauncher | ✓ | ✓ | Qt6 Wayland |
| hedgewars | ✓ | ✓ | SDL2 Wayland |
| superTuxKart | ✓ | ✓ | SDL2/OpenGL Wayland |
| inkscape | ✓ | ✓ (XWayland) | GTK3; some ops X11-dependent |
| gimp | ✓ | ✓ (XWayland) | GTK2; GIMP 3 would be native |
| simplescreenrecorder | ✓ | ✓ (XWayland) | No Wayland native; XWayland accepted |
| galculator | ✓ | ✓ (XWayland) | GTK2; XWayland accepted |
| audacity | ✓ | ✓ (XWayland) | Experimental Wayland support |
| xnviewmp | ✓ | ✓ (XWayland) | Proprietary; XWayland accepted |
| tinymediamanager | ✓ | ✓ (XWayland) | Java AWT; XWayland accepted |
| xchm | ✓ | ✓ (XWayland) | wxWidgets; XWayland accepted |
| conky | ✓ | ✓ (XWayland) | Limited Wayland support |
| Steam | ✓ | ✓ (XWayland) | Requires X11 or XWayland |
| Wine/Winetricks | ✓ | ✓ (XWayland) | Requires X11 or XWayland |
| RustDesk | ✓ | ✓ (XWayland) | Linux client is X11-only upstream |
| light | ✓ | ✓ | sysfs-level backlight; works on both |
| i3lock-color | ✓ | ✗ | X11 only; KDE uses kscreenlocker (built-in) |
| xclip | ✓ | ✗ | Replaced by `wl-clipboard` |
| wmctl | ✓ | ✗ pending | KWin D-Bus backend needed (Step 8) |
| x11vnc | ✓ | ✗ | Removed from Plasma profiles (Step 7) |
| xfwm4 | ✓ | ✗ | XFCE WM only; KWin replaces on Wayland |
| paprefs | ✓ | ✗ | GTK2 PulseAudio prefs; not needed with PipeWire |
| xf86videodummy | ✓ | ✗ | X11 headless driver; guarded in Step 5 |

---

## 5. Machine Migration Guide

To migrate an existing machine from XFCE to Plasma, change the `imports` in
`machines/<name>/configuration.nix`:

```nix
# Before (XFCE)
imports = [ ./hardware-configuration.nix ../../profiles/xfce/desktop.nix ];

# After (Plasma/Wayland)
imports = [ ./hardware-configuration.nix ../../profiles/plasma/desktop.nix ];
```

Machine-level options that may need updating when migrating:

| XFCE Option | Plasma Equivalent |
|-------------|-------------------|
| `system.xfce.*` | Not needed (Plasma manages its own config) |
| `system.x11.xft.dpi = N` | `environment.sessionVariables.QT_SCALE_FACTOR = "..."` |
| `system.x11.autolock.enable` | Not needed (KDE kscreenlocker is built-in) |
| `system.xfce.panel.*` | `system.plasma.panel.*` (from Step 2) |
| `system.xfce.displays.*` | KDE Display Configuration |
| `system.xfce.desktop.background` | `system.plasma.desktop.background` |
| `security.pam.services.lightdm.enableGnomeKeyring` | `security.pam.services.sddm.enableGnomeKeyring` |

---

## 6. Implementation Order Summary

| Step | Task | Files | Depends On |
|------|------|-------|-----------|
| 1 | Create `options/system/wayland/default.nix` | New file + `options/system/default.nix` | — |
| 2 | Create `options/system/plasma/default.nix` | New file + `options/system/default.nix` | Step 1 |
| 3 | Rewrite `profiles/plasma/base.nix` | Existing file | Steps 1–2 |
| 4 | Add `obs-xdg-portal` to OBS option | `options/apps/media/obs/default.nix` | Step 1 |
| 5 | Guard `xf86videodummy` in RustDesk option | `options/services/raw/rustdesk.nix` | Step 1 |
| 6 | Guard Steam `xdg.menu` in games option | `options/apps/games/steam/default.nix` | — |
| 7 | Add Wayland assertion to `x11vnc` option | `options/services/raw/x11vnc.nix` | Step 1 |
| 8 | Add KWin D-Bus backend to `wmctl` package | `packages/wmctl/` | — |
| 9 | Create `profiles/plasma/desktop.nix` | New file | Step 3 |
| 10 | Create `profiles/plasma/develop.nix` | New file | Step 9 |
| 11 | Create `profiles/plasma/theater.nix` | New file | Step 9 |
| 12 | Create `profiles/plasma/laptop.nix` | New file | Step 9 |
| 13 | Test build + boot on `vm-test` with Plasma profile | `machines/vm-test/configuration.nix` | Steps 9–12 |
| 14 | Migrate first physical machine to Plasma | `machines/<name>/configuration.nix` | Step 13 |

Steps 1–3 are the critical path. Steps 4–7 and Step 8 can proceed in parallel once Step 1 is done.

---

## 7. Open Questions / Future Work

1. **`plasma-manager`**: The `plasma-manager` NixOS module enables declarative KDE panel layout,
   global shortcuts, and system settings configuration. Evaluate before implementing
   `options/system/plasma/` deeply — it may provide a better foundation than writing KDE config
   files directly.

2. **SDDM theme**: XFCE uses LightDM Slick greeter with Adwaita-dark. SDDM should be configured
   with a matching dark theme (e.g. `sddm-astronaut-theme` or a custom NixOS-generated theme) for
   visual consistency.

3. **Conky on Plasma**: Conky's Wayland support is limited and runs via XWayland. For theater
   machines specifically, a KDE Plasma widget may be a cleaner replacement.

4. **RustDesk Wayland**: Monitor upstream for native Wayland support. When it ships, the
   `xf86videodummy` guard in Step 5 can be removed and `allowLinuxHeadless` re-evaluated.

5. **`system.x11.xft.*` naming**: These options now serve as a neutral font/theme settings store
   shared by both X11 and Plasma modules. Consider renaming to `system.theme.*` in a future cleanup
   pass to make the shared intent explicit.

6. **Qt5 vs Qt6 theming**: Plasma natively manages Qt6. Qt5 apps under Plasma use Kvantum via the
   install in Step 2. As Qt5 apps phase out upstream, Kvantum configuration can be simplified.

7. **`paprefs`**: This PulseAudio preferences UI is included in XFCE profiles but omitted from
   Plasma. PipeWire with `pavucontrol` covers the same needs. If needed, `paprefs` also runs via
   XWayland.
