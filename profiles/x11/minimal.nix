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
    ../../modules/network/firefox.nix
    ../../modules/network/network-manager.nix
    ../../modules/desktop/backgrounds.nix
    ../../modules/desktop/fonts.nix
    ../../modules/desktop/icons.nix
    ../../modules/desktop/xdg.nix
    ../../modules/desktop/xorg.nix
  ];

  programs.filezilla.enable = true;     # Network/Transfer
  programs.file-roller.enable = true;   # Generic Gnome file archive utility needed for Thunar
  programs.smplayer.enable = true;      # UI wrapper around mplayer with click to pause
  programs.xnviewmp.enable = true;      # Excellent image viewer

  services.fwupd.enable = true;         # Firmware update tool for BIOS, etc...
  services.gvfs.enable = true;          # GVfs virtual filesystem

  environment.systemPackages = with pkgs; [

    # Network

    # Media
    audacious                           # Lightweight advanced audio player
    audacious-plugins                   # Additional codecs support for audacious
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

    # Utilities
    galculator                          # Simple calculator
  ];
}
