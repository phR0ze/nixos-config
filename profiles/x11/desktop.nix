# Full desktop independent X11 configuration
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  imports = [
    #../../modules/hardware/scanners.nix
  ];

  # Additional programs
  programs.evince.enable = true;        # Document viewer for PDF, djvu, tiff, dvi, XPS, cbr, cbz, cb7, cbt

  environment.systemPackages = with pkgs; [

    # System
    jdk17                               # Needed for: minecraft

    # Networking
    firefox                             # Standalone web browser from mozilla.org 
    filezilla                           # Network/Transfer
    freerdp                             # RDP client plugin for remmina
    networkmanager-openvpn              # NetworkManager VPN plugin for OpenVPN
    openvpn                             # An easy-to-use, robust and highly configurable VPN (Virtual Private Network)
    qbittorrent                         # Freatureful free BitTorrent client
    remmina                             # Nice remoting UI for RDP and other protocols
    vopono                              # Run applications through VPN connections in network namespaces
    update-systemd-resolved             # OpenVPN systemd-resolved updater
    zoom-us                             # Video conferencing application

    # Media
    audacious                           # Lightweight advanced audio player
    audacious-plugins                   # Additional codecs support for audacious
    dvdbackup                           # Command line tool for ripping DVDs
    libdvdcss                           # DVD decrypting media codec support
    lxdvdrip                            # Command line tool for ripping, shrinking and burning DVDs 
    flac                                # Free lossless audio codec
    handbrake                           # Video encoding tool for mp4/mkv
    lame                                # High quality MPEG layer III audio encoder
    mkvtoolnix                          # Cross-platform tools for Matroska
    smplayer                            # UI wrapper around mplayer with click to pause
    vlc                                 # Multi-platform MPEG, VCD/DVD, and DivX player
    x264                                # Open Source H264/AVC video encoder, depof: smplayer
    yt-dlp                              # Command-line tool to download videos from YouTube.com and other sites

    # Game
    steam                               # Digital distribution platform from Valve

    # Office
    aspell                              # Spell checker for many languages, but no longer maintained
    aspellDicts.en                      # Aspell dictionary for English
    hunspell                            # LibreOffice spell checker and actively maintained
    geany                               # Fast and lightweight IDE
    keepassxc                           # Offline password manager with many features
    veracrypt                           # Free Open-Source filesystem encryption

    # Development
    android-tools                       # Android platform tools
    android-udev-rules                  # Android udev rules list aimed to be the most comprehensive on the net

    # Utilities

    # Not available in NixOS
#    arcologout                         # Simple clean logout overlay from
#    kvantum                            # SVG-based theme engine for Qt5/Qt6 including Arc-Dark
#    winff                              # GUI for ffmpeg, repo: cyberlinux
#    wmctl                              # Rust X11 automation
#    xnviewmp                           # A digital photo organizer, repo: cyberlinux

    # Patch prismlauncher for offline mode
    (prismlauncher.override (prev: {
      prismlauncher-unwrapped = prev.prismlauncher-unwrapped.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [ ../../patches/prismlauncher/offline.patch ];
      });
    }))
  ];
}

# vim:set ts=2:sw=2:sts=2
