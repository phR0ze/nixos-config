# base.nix provides a minimal XFCE desktop environment
#
# ### Dependencies
# - `console.desktop` gets enabled for the underlying shell environment
#
# ### Features
# - Minimal general purpose desktop environment
# - Optional autologin of the primary user
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.layers.xfce.base;
in
{
  options = {
    layers.xfce.base = {
      enable = lib.mkEnableOption "Enable the xfce base layer";
      autologin = lib.mkEnableOption "Automatically log the primary user in after boot";
      lowMemory = lib.mkEnableOption "Enable the low memory configuration";

      resolution = lib.mkOption {
        description = lib.mdDoc ''
          Display resolution, see `system.desktop.xfce.resolution`. Defaults to `host.resolution`, which
          a host or a higher xfce layer can override - leaving either axis at 0 lets the display
          autodetect.
        '';
        type = lib.types.submodule {
          options = {
            x = lib.mkOption {
              description = lib.mdDoc "Horizontal resolution in pixels";
              type = lib.types.int;
              default = 0;
            };
            y = lib.mkOption {
              description = lib.mdDoc "Vertical resolution in pixels";
              type = lib.types.int;
              default = 0;
            };
          };
        };
        default = { };
        example = { x = 1920; y = 1080; };
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # Console desktop dependency with passed along configuration
      layers.console.desktop = {
        enable = true;
        lowMemory = lib.mkIf cfg.lowMemory true;
      };

      # Enable XFCE
      system.desktop.xfce = {
        enable = true;
        resolution = { inherit (cfg.resolution) x y; };
      };
      system.dmenu.enable = true;                   # Configure dmenu
      system.dconf.enable = true;                   # General configuration manager that replaces gconf

      devices.audio.enable = true;                  # Install necessary support for audio
      devices.bluetooth.enable = true;              # Install necessary support for bluetooth
      devices.network.networkManager.enable = true; # Enable network manager

      apps.media.qview.enable = true;               # Simple image viewer with webp support
      apps.media.smplayer.enable = true;            # UI wrapper around mplayer with click to pause
      apps.system.devilspie2.enable = true;         # Lua scripted window rules for X11
      apps.system.hardinfo.enable = true;           # A system information and benchmark tool
      apps.system.neovide.enable = true;            # Graphical interface for Neovim
      apps.system.wezterm.enable = true;            # GPU accelerated terminal
      apps.network.firefox.enable = true;           # Mozilla browser
      apps.network.filezilla.enable = true;         # Network/Transfer

      services.fwupd.enable = true;                 # Firmware update tool for BIOS, etc...

      # XFCE comes with a slimmed down version of GVFS by default so we need to set a package override
      # to include smb:// support in Thunar
      services.gvfs.enable = true;
    #  services.gvfs = {
    #    enable = true;
    #    package = lib.mkForce pkgs.gnome.gvfs;
    #  };

      # Configure gnome keyring for VPN and Copilot and automatically unlock on login
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.lightdm.enableGnomeKeyring = true;

      # Link the desktop-assets package's content to the system path /run/current-system/sw
      # - searches all packages that have paths matching the list and merge links them
      environment.pathsToLink = [
        "/share/backgrounds"                        # /run/current-system/sw/share/backgrounds
        "/share/icons/hicolor"                      # /run/current-system/sw/share/icons/hicolor
      ];

      environment.systemPackages = with pkgs; [

        # Custom packages
        desktop-assets                              # Custom package for wallpaper and other settings
        wmctl                                       # Custom package for wmctl

        # System
        file-roller                           # Generic Gnome file archive utility needed for Thunar
        desktop-file-utils                    # Command line utilities for working with desktop entries
        i3lock-color                      # Simple lightweight screen locker
        paprefs                                # Pulse audio server preferences for simultaneous output
        pulseaudio                            # Provides pactl for sink volume control

        # VPN
        networkmanager-openvpn              # NetworkManager VPN plugin for OpenVPN

        # Network
        freerdp                             # RDP client plugin for remmina
        remmina                             # Nice remoting UI for RDP and other protocols
        #tdesktop                                   # Telegram Desktop messaging app

        # Office
        keepassxc                           # Offline password manager with many features

        # Utilities
        conky                               # Advanced, highly configurable system monitor
        exiftool                             # A tool to read, write and edit EXIF meta information
        gnome-calculator                      # Calculator
        gnome-multi-writer                 # Tool for writing an ISO file to multiple USB devices at once
        htop                                 # Better top tool
        brightnessctl                        # Control backlights for screen and keyboard
        system-config-printer               # GTK app for CUPS printing administration
      ];
    }

    # Autologin
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf cfg.autologin {
      system.x11.autologin = true;                  # log the secret admin account straight into the session
    })
  ]);
}
