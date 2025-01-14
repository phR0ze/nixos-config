# xorg.nix provides a minimal xorg environment without a window manager
#
# ### Features
# - 
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, ... }:
let
 # machine = config.machine;
in
{
  imports = [
    ./base.nix
    ../../modules/hardware/audio.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/printers.nix
    ../../modules/hardware/video.nix
    ../../modules/desktop/backgrounds/opt.nix
    ../../modules/desktop/icons.nix
  ];

  # Enable NetworkManager
  network.network-manager.enable = true;

  # Office
  programs.geany.enable = true;         # Simple text editor
  programs.evince.enable = true;        # Document viewer for PDF, djvu, tiff, dvi, XPS, cbr, cbz, cb7, cbt

  # Multimedia
  programs.qview.enable = true;         # Simple image viewer with webp support
  programs.smplayer.enable = true;      # UI wrapper around mplayer with click to pause

  # Network
  programs.firefox.enable = true;       # Mozilla browser
  programs.filezilla.enable = true;     # Network/Transfer

  # System
  programs.dmenu.enable = true;         # Configure dmenu
  programs.file-roller.enable = true;   # Generic Gnome file archive utility needed for Thunar
  programs.hardinfo.enable = true;      # A system information and benchmark tool
  services.fwupd.enable = true;         # Firmware update tool for BIOS, etc...
  services.gvfs.enable = true;          # GVfs virtual filesystem

  # Configure gnome keyring for VPN and Copilot and automatically unlock on login
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.lightdm.enableGnomeKeyring = true;

  environment.systemPackages = with pkgs; [

    # System
    desktop-file-utils                  # Command line utilities for working with desktop entries
    filelight                           # View disk usage information
#    gnome-dconf-editor                 # General configuration manager that replaces gconf
    i3lock-color                        # Simple lightweight screen locker
    paprefs                             # Pulse audio server preferences for simultaneous output

    # VPN
    networkmanager-openvpn              # NetworkManager VPN plugin for OpenVPN

    # Network
    freerdp                             # RDP client plugin for remmina
    remmina                             # Nice remoting UI for RDP and other protocols
    #tdesktop                            # Telegram Desktop messaging app

    # Office
    keepassxc                           # Offline password manager with many features

    # Utilities
    alacritty                           # GPU accelerated terminal
    alacritty-theme                     # GPU accelerated terminal themes
    conky                               # Advanced, highly configurable system monitor
    exiftool                            # A tool to read, write and edit EXIF meta information
    galculator                          # Simple calculator
    gnome-multi-writer                  # Tool for writing an ISO file to multiple USB devices at once
    htop                                # Better top tool
    light                               # Control backlights for screen and keyboard
    sops                                # Industry standard encryption at rest
    veracrypt                           # Free Open-Source filesystem encryption
  ];

}
