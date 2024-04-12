# Full desktop independent X11 configuration
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  imports = [
    #../../modules/hardware/scanners.nix
    ../../modules/development/vscode.nix
    #../../modules/virtualization/virtualbox.nix causing weird networking delays on boot
  ];

  # Additional programs and services
  programs.evince.enable = true;        # Document viewer for PDF, djvu, tiff, dvi, XPS, cbr, cbz, cb7, cbt
  programs.steam.enable = true;         # Digital distribution platform from Valve
  programs.prismlauncher.enable = true; # Minecraft launcher

  environment.systemPackages = with pkgs; [

    # Network
    freerdp                             # RDP client plugin for remmina
    networkmanager-openvpn              # NetworkManager VPN plugin for OpenVPN
    nfs-utils                           # Linux user-space NFS utilities
    openvpn                             # An easy-to-use, robust and highly configurable VPN (Virtual Private Network)
    qbittorrent                         # Freatureful free BitTorrent client
    remmina                             # Nice remoting UI for RDP and other protocols
    #tdesktop                            # Telegram Desktop messaging app
    vopono                              # Run applications through VPN connections in network namespaces
    update-systemd-resolved             # OpenVPN systemd-resolved updater
    zoom-us                             # Video conferencing application

    # Media
    asunder                             # A lean and friendly audio CD ripper and encoder
    audacity                            # Audio editor - cross platform, tried and tested
    brasero                             # Burning tool, alt: k3b, xfburn
    devede                              # A program to create VideoDVDs and CDs
    gnome.cheese                        # Take photos and videos with your webcam, with fun graphical effects
    dvdbackup                           # Command line tool for ripping DVDs
    gimp                                # Excellent image editor
    flac                                # Free lossless audio codec
    kodi                                # A software media player and entertainment hub for digital media
    kolourpaint                         # Paint application that saves jpg in format for GFXBoot
    libdvdcss                           # DVD decrypting media codec support
    losslesscut-bin                     # Crossplatform GUI tool for lossless trimming/cuttong of video/audio files
    lxdvdrip                            # Command line tool for ripping, shrinking and burning DVDs 
    handbrake                           # Video encoding tool for mp4/mkv
    lame                                # High quality MPEG layer III audio encoder
    mkvtoolnix                          # Cross-platform tools for Matroska
    mpv                                 # General purpose media player, fork of MPlayer and mplayer2
    openshot-qt                         # Simple powerful Video Editor, alt: pitivi, kdenlive
    #obs-studio                          # Free and open source software for video recording and live streaming
    simplescreenrecorder                # Awesome screen recorder
    x264                                # Open Source H264/AVC video encoder, depof: smplayer
    yt-dlp                              # Command-line tool to download videos from YouTube.com and other sites

    # Game
    #cartridges                          # A GTK4 + Libadwaita game launcher
    lutris                              # Open Source gaming platform for GNU/Linux
    wine                                # An Open Source implementation of the Windows API on top of X, OpenGL, and Unix
    winetricks                          # A script to install DLLs needed to work around problems in Wine
    protontricks                        # A simple wrapper for running Winetricks commands for Proton-enabled games

    # Office
    hunspell                            # LibreOffice spell checker and actively maintained
    hunspellDicts.en_US                 # LibreOffice spell checker and actively maintained
    keepassxc                           # Offline password manager with many features
    libreoffice-fresh                   # Comprehensive, professional-quality productivity suite
    scribus                             # Open Source Desktop Publishing

    # Development
    android-tools                       # Android platform tools
    android-udev-rules                  # Android udev rules list aimed to be the most comprehensive on the net

    # Utilities
    awf                                 # A widget factory for viewing theme changes
    conky                               # Advanced, highly configurable system monitor
    exiftool                            # A tool to read, write and edit EXIF meta information
    gnome-multi-writer                  # Tool for writing an ISO file to multiple USB devices at once
    hardinfo                            # A system information and benchmark tool
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
  ];
}
