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
    ../../modules/networking/network-manager.nix
  ];

  # Xserver configuration
  #-------------------------------------------------------------------------------------------------
  services.xserver = {
    enable = true;

    desktopManager = {
      xterm.enable = false;
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

  # Logind configuration
  # - Defaults were changed here https://github.com/NixOS/nixpkgs/pull/16021
  # - Want shutdown to kill all users process immediately for fast shutdown
  # ------------------------------------------------------------------------------------------------
  services.logind.extraConfig = ''
    KillUserProcesses=yes
    UserStopDelaySec=0
  '';

  # Journald configuration
  # ------------------------------------------------------------------------------------------------
  services.journald.extraConfig = ''
    SystemMaxUse=256M
  '';

  # Other programs and services
  # ------------------------------------------------------------------------------------------------
  programs.file-roller.enable = true;   # Generic Gnome file archive utility needed for Thunar

  services.fwupd.enable = true;         # Firmware update tool for BIOS, etc...
  services.gvfs.enable = true;          # GVfs virtual filesystem
  services.timesyncd.enable = true;

  environment.systemPackages = with pkgs; [

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
  ];
}
