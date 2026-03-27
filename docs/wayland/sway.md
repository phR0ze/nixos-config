# Wayland Desktop Environment Migration Spec

## Overview

Migration from XFCE (X11) to a lightweight Wayland-native desktop stack using Sway as the compositor,
preserving the existing workflow and feature set.

## Current XFCE Setup

### Panel 1 — Taskbar (bottom, full width)
- Applications menu (icon: cyberlinux, label: "Apps")
- Window tasklist (no grouping, no scrolling)
- System tray
- Power manager plugin
- Notification plugin
- PulseAudio plugin (keyboard shortcuts + notifications enabled)
- Clock

### Panel 2 — Dock (auto-hiding, bottom-right)
Launchers in order:
1. WezTerm
2. Thunar
3. Jellyfin
4. SMPlayer
5. HandBrake
6. VLC
7. FileZilla
8. Firefox
9. LibreOffice Calc
10. LibreOffice Writer
11. Reboot

### Window Manager (xfwm4)
- 2 workspaces
- Click-to-focus
- Compositing enabled
- Window snapping (to borders)
- Tile on move
- Arc-Dark theme
- Window placement: center
- Button layout: `O|SHMC`

### Power Manager
- Presentation mode enabled
- DPMS disabled
- Power button: shutdown
- Sleep button: suspend
- Hibernate button: hibernate
- No tray icon

---

## Target Stack

| Role | Component | Notes |
|---|---|---|
| Compositor | `sway` | Wayland-native, i3-compatible config |
| Panel | `waybar` | Replaces XFCE panel-1 (taskbar) |
| Dock | `nwg-dock` | Replaces XFCE panel-2 (auto-hiding launcher dock) |
| App launcher | `fuzzel` | Keyboard-launched; replaces applications menu |
| Notifications | `mako` | Wayland-native; replaces xfce4-notifyd |
| Lock screen | `swaylock` | Replaces xfce4-power-manager lock |
| Idle daemon | `swayidle` | Handles screen timeout and suspend |
| Power menu | `wlogout` | Graphical shutdown/reboot/suspend/hibernate menu |
| Display management | `kanshi` + `nwg-displays` | Auto display profiles + GUI; replaces xfce4-display-settings |
| Screenshots | `grim` + `slurp` | Replaces xfce4-screenshooter |
| Clipboard | `wl-clipboard` + `cliphist` | Wayland clipboard + history |
| GTK theming | `nwg-look` | Sets GTK theme/icons/fonts; replaces XFCE appearance settings |
| Polkit agent | `lxqt-policykit` | GUI password prompts for privileged actions |
| File manager | `thunar` | Keep as-is; runs via XWayland |
| Network | `nm-applet --indicator` | Keep as-is; add `--indicator` flag for Wayland tray |
| Volume control | `pavucontrol` | Keep as-is; already installed |

---

## Waybar Configuration Requirements

### Left
- Sway workspaces module (2 workspaces)
- Sway app launcher button (opens `fuzzel`)

### Center
- Taskbar / window list (`sway/window` or `wlr/taskbar`)

### Right
- System tray
- PulseAudio module (click opens `pavucontrol`)
- Clock (match current format: no seconds, no meridiem)
- Power button (opens `wlogout`)

---

## Sway Configuration Requirements

- Floating window placement: centered
- Click-to-focus
- 2 named workspaces: `Workspace 1`, `Workspace 2`
- Window snapping / smart borders
- Arc-Dark GTK theme
- Keyboard shortcuts:
  - App launcher: `fuzzel`
  - Lock screen: `swaylock`
  - Screenshot region: `grim` + `slurp`
  - Power menu: `wlogout`

### Autostart (exec directives)
- `waybar`
- `nwg-dock`
- `mako`
- `swayidle`
- `kanshi`
- `nm-applet --indicator`
- `lxqt-policykit`
- `/usr/lib/polkit-1/polkitd`
- `wl-paste --watch cliphist store` (clipboard history daemon)

---

## swayidle Configuration

```
timeout 300  'swaylock -f'
timeout 600  'swaymsg "output * dpms off"'
resume       'swaymsg "output * dpms on"'
before-sleep 'swaylock -f'
```

---

## Apps That Need No Changes

These run natively on Wayland or work acceptably via XWayland:

| App | Status |
|---|---|
| WezTerm | Native Wayland support |
| Firefox | Native Wayland support |
| Chromium | Native Wayland support |
| Thunar | XWayland — no issues |
| VLC | XWayland — no issues |
| SMPlayer | XWayland — no issues |
| Jellyfin | XWayland — no issues |
| HandBrake | XWayland — no issues |
| FileZilla | XWayland — no issues |
| LibreOffice | XWayland — no issues |
| pavucontrol | XWayland — no issues |

---

## Trade-offs vs XFCE

### Gains
- True Wayland benefits: lower input latency, no screen tearing
- Lighter RAM footprint
- Explicit, reproducible text-based configuration

### Losses
- No unified settings GUI — all configuration via text files
- Display hotplug less seamless until `kanshi` profiles are configured
- Dock requires separate component (`nwg-dock`) with its own config file
- ~6-8 additional components to install and configure vs XFCE's integrated suite
