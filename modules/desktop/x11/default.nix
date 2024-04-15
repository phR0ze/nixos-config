# X11 minimal configuration
#
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  imports = [
    ../../terminal
    ../../hardware/audio.nix
    ../../hardware/bluetooth.nix
    ../../hardware/firmware.nix
    ../../hardware/printers.nix
    ../../hardware/video.nix
    ../../network/firefox.nix
    ../../network/network-manager.nix
    ../backgrounds/opt.nix
    ../fonts.nix
    ../icons.nix
    ../xdg.nix
    ../xorg.nix
  ];

  programs.geany.enable = true;         # Simple text editor
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

    # Themes, icons and backgrounds
    arc-theme                           # Flat theme with transparent elements for GTK 3 and GTK 2
    arc-kde-theme                       # A port of the arc theme for Plasma
    paper-icon-theme                    # Modern icon theme designed around bold colors
    numix-cursor-theme                  # Numix cursor theme

    # Utilities
    galculator                          # Simple calculator
    alacritty                           # GPU accelerated terminal
    alacritty-theme                     # GPU accelerated terminal themes
  ];
}
