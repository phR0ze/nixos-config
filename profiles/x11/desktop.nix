# Full desktop independent X11 configuration
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  imports = [
    #../../modules/hardware/scanners.nix
    ../../modules/development/vscode.nix
    ../../modules/virtualization/virtualbox.nix
  ];

  # Additional programs
  programs.evince.enable = true;        # Document viewer for PDF, djvu, tiff, dvi, XPS, cbr, cbz, cb7, cbt

  environment.systemPackages = with pkgs; [

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
    gnome.cheese                        # Take photos and videos with your webcam, with fun graphical effects
    dvdbackup                           # Command line tool for ripping DVDs
    gimp                                # Excellent image editor
    flac                                # Free lossless audio codec
    libdvdcss                           # DVD decrypting media codec support
    lxdvdrip                            # Command line tool for ripping, shrinking and burning DVDs 
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
    hunspell                            # LibreOffice spell checker and actively maintained
    hunspellDicts.en_US                 # LibreOffice spell checker and actively maintained
    geany                               # Fast and lightweight IDE
    keepassxc                           # Offline password manager with many features
    libreoffice-fresh                   # Comprehensive, professional-quality productivity suite

    # Development
    android-tools                       # Android platform tools
    android-udev-rules                  # Android udev rules list aimed to be the most comprehensive on the net

    # Utilities
    awf                                 # A widget factory for viewing theme changes
    conky                               # Advanced, highly configurable system monitor
    gnome-multi-writer                  # Tool for writing an ISO file to multiple USB devices at once
    light                               # Control backlights for screen and keyboard
    veracrypt                           # Free Open-Source filesystem encryption

    # System
    jdk17                               # Needed for: minecraft


    # Not available in NixOS
#    arcologout                         # Simple clean logout overlay from
#    kvantum                            # SVG-based theme engine for Qt5/Qt6 including Arc-Dark
#    winff                              # GUI for ffmpeg, repo: cyberlinux
#    wmctl                              # Rust X11 automation
#    xnviewmp                           # A digital photo organizer, repo: cyberlinux
#'tiny-media-manager'        # Cross platform media manager, repo: cyberlinux

    # Patch prismlauncher for offline mode
    (prismlauncher.override (prev: {
      prismlauncher-unwrapped = prev.prismlauncher-unwrapped.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [ ../../patches/prismlauncher/offline.patch ];
      });
    }))
  ];
}

# vim:set ts=2:sw=2:sts=2
