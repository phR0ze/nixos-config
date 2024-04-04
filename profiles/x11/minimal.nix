# Minimal desktop independent X11 configuration
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  imports = [
    ../cli
    ../../modules/hardware/audio.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/firmware.nix
    ../../modules/hardware/printers.nix
    ../../modules/hardware/opengl.nix
    ../../modules/xdg.nix
    ../../modules/fonts.nix
    ../../modules/network/firefox.nix
    ../../modules/network/network-manager.nix
    ../../modules/desktop/backgrounds.nix
    ../../modules/desktop/icons.nix
  ];

  # Xserver configuration
  #-------------------------------------------------------------------------------------------------
  services.xserver = {
    enable = true;

    desktopManager = {
      xterm.enable = false;

      # Controls how the ~/.background-image is used as a background
      wallpaper.mode = "fill";
    };

    displayManager = {
      lightdm = {
        enable = true;
        #background = "";
        # enso, mini, tiny, slick, mobile, gtk, pantheon
        greeters.slick = {
          enable = true;
          theme.name = "Zukitre-dark";
        };
      };

      # Conditionally autologin based on install settings
      autoLogin = {
        enable = args.settings.autologin;
        user = args.settings.username;
      }; 
    };

    # Arch Linux recommends libinput and Xfce uses it in its settings manager
    libinput = {
      enable = true;
##      touchpad = {
##        accelSpeed = "0.7";
##        tappingDragLock = false;
##        naturalScrolling = true;
##      };
    };
  };

  # GTK/Qt themese
  # - https://nixos.org/manual/nixos/unstable/#sec-x11-gtk-and-qt-themes
  # ------------------------------------------------------------------------------------------------
  #qt.enable = true;
  #qt.platformTheme = "gtk2";
  #qt.style = "gtk2";

  # GTK gsettings
  # ------------------------------------------------------------------------------------------------
#  services.xserver.desktopManager.gnome = {
#    extraGSettingsOverrides = ''
#      # Change default background
#      [org.gnome.desktop.background]
#      picture-uri='file://${pkgs.nixos-artwork.wallpapers.mosaic-blue.gnomeFilePath}'
#
#      # Favorite apps in gnome-shell
#      [org.gnome.shell]
#      favorite-apps=['org.gnome.Console.desktop', 'org.gnome.Nautilus.desktop']
#    '';
#
#    extraGSettingsOverridePackages = [
#      pkgs.gsettings-desktop-schemas # for org.gnome.desktop
#      pkgs.gnome.gnome-shell # for org.gnome.shell
#    ];
#  };

  # Other programs and services
  # ------------------------------------------------------------------------------------------------
  programs.file-roller.enable = true;   # Generic Gnome file archive utility needed for Thunar

  services.fwupd.enable = true;         # Firmware update tool for BIOS, etc...
  services.gvfs.enable = true;          # GVfs virtual filesystem
  services.timesyncd.enable = true;

  environment.systemPackages = with pkgs; [

    # Network
    filezilla                           # Network/Transfer

    # Media
    audacious                           # Lightweight advanced audio player
    audacious-plugins                   # Additional codecs support for audacious
    smplayer                            # UI wrapper around mplayer with click to pause
    vlc                                 # Multi-platform MPEG, VCD/DVD, and DivX player

    # System
    desktop-file-utils                  # Command line utilities for working with desktop entries
    filelight                           # View disk usage information
#    gnome-dconf-editor                 # General configuration manager that replaces gconf
    i3lock-color                        # Simple lightweight screen locker
    paprefs                             # Pulse audio server preferences for simultaneous output

    # Themes and icons
    arc-theme                           # Flat theme with transparent elements for GTK 3 and GTK 2
    arc-kde-theme                       # A port of the arc theme for Plasma
    paper-icon-theme                    # Modern icon theme designed around bold colors
    numix-cursor-theme                  # Numix cursor theme

    #(pkgs.callPackage ../../pkgs/hicolor {})

    # Utilities
    #galculator                        # Simple calculator
  ];
}
