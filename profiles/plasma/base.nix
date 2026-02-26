# KDE Plasma 6 minimal desktop configuration
#
# ### Features
# - Directly installable: minimal general purpose desktop environment
# --------------------------------------------------------------------------------------------------
{ pkgs, lib, ... }:
{
  imports = [
    ../base.nix
  ];

  # Enable Plasma 6 with SDDM
  system.x11.enable = true;                   # Fonts, XFT, XDG, themes, libinput
  services.xserver.displayManager.lightdm.enable = lib.mkForce false;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  services.desktopManager.plasma6.enable = true;

  system.dconf.enable = true;                 # General configuration manager for GTK app settings
  net.network-manager.enable = true;          # Enable network manager
  devices.audio.enable = true;                # Install necessary support for audio
  devices.bluetooth.enable = true;            # Install necessary support for bluetooth

  apps.media.qview.enable = true;             # Simple image viewer with webp support
  apps.media.smplayer.enable = true;          # UI wrapper around mplayer with click to pause
  apps.network.firefox.enable = true;         # Mozilla browser
  apps.network.filezilla.enable = true;       # Network/Transfer
  apps.system.hardinfo.enable = true;         # A system information and benchmark tool
  apps.system.neovide.enable = true;          # Graphical interface for Neovim
  apps.system.ghostty.enable = true;          # GPU accelerated terminal

  services.fwupd.enable = true;               # Firmware update tool for BIOS, etc...
  services.gvfs.enable = true;

  # Link the desktop-assets package's content to the system path /run/current-system/sw
  # - searches all packages that have paths matching the list and merge links them
  environment.pathsToLink = [
    "/share/backgrounds"  # /run/current-system/sw/share/backgrounds
    "/share/icons/hicolor"  # /run/current-system/sw/share/icons/hicolor
  ];

  environment.systemPackages = with pkgs; [

    # Custom packages
    desktop-assets                            # Custom package for wallpaper and other settings
    wmctl                                     # Custom package for wmctl

    # System
    desktop-file-utils                  # Command line utilities for working with desktop entries

    # VPN
    networkmanager-openvpn            # NetworkManager VPN plugin for OpenVPN

    # Network
    freerdp                           # RDP client plugin for remmina
    remmina                           # Nice remoting UI for RDP and other protocols

    # Office
    keepassxc                         # Offline password manager with many features

    # Utilities
    conky                             # Advanced, highly configurable system monitor
    exiftool                           # A tool to read, write and edit EXIF meta information
    gnome-multi-writer               # Tool for writing an ISO file to multiple USB devices at once
    htop                               # Better top tool

    # Wayland support
    kdePackages.xwaylandvideobridge            # Enables screen sharing under Wayland
  ];
}
