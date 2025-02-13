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
    ../modules/hardware/audio.nix
    ../modules/hardware/bluetooth.nix
    ../modules/hardware/printers.nix
  ];

  networking.network-manager.enable = true;   # Enable network manager

  apps.office.geany.enable = true;            # Simple text editor
  apps.office.evince.enable = true;           # Document viewer for PDF, djvu, tiff, dvi, XPS, cbr, cbz, cb7, cbt
  apps.media.qview.enable = true;             # Simple image viewer with webp support
  apps.media.smplayer.enable = true;          # UI wrapper around mplayer with click to pause

  apps.network.firefox.enable = true;         # Mozilla browser
  apps.network.filezilla.enable = true;       # Network/Transfer

  apps.utils.dmenu.enable = true;             # Configure dmenu
  apps.utils.hardinfo.enable = true;          # A system information and benchmark tool

  services.fwupd.enable = true;               # Firmware update tool for BIOS, etc...
  programs.file-roller.enable = true;         # Generic Gnome file archive utility needed for Thunar

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
    "/share/backgrounds"  # /run/current-system/sw/share/backgrounds
    "/share/icons/hicolor"  # /run/current-system/sw/share/icons/hicolor
  ];

  environment.systemPackages = with pkgs; [

    # Custom packages
    desktop-assets
    rdutil
    wmctl

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
