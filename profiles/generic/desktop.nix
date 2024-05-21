# XFCE full desktop configuration
#
# ### Features
# - Directly installable: full general purpose desktop environment
# --------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  imports = [
    ../../modules/terminal
    ../../modules/hardware/audio.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/firmware.nix
    ../../modules/hardware/printers.nix
    ../../modules/hardware/video.nix
    ../../modules/desktop/backgrounds/opt.nix
    ../../modules/desktop/icons.nix
  ];

  # Enable XFCE and all needed components
  services.xserver.desktopManager.xfce.enable = true;

  # Additional programs and services
  programs.dmenu.enable = true;         # Configure dmenu
  programs.evince.enable = true;        # Document viewer for PDF, djvu, tiff, dvi, XPS, cbr, cbz, cb7, cbt
  programs.steam.enable = true;         # Digital distribution platform from Valve
  programs.qbittorrent.enable = true;   # Excellent bittorrent client
  programs.prismlauncher.enable = true; # Minecraft launcher

  programs.geany.enable = true;         # Simple text editor
  programs.firefox.enable = true;       # Mozilla browser
  programs.filezilla.enable = true;     # Network/Transfer
  programs.file-roller.enable = true;   # Generic Gnome file archive utility needed for Thunar
  programs.smplayer.enable = true;      # UI wrapper around mplayer with click to pause
  programs.xnviewmp.enable = true;      # Excellent image viewer

  services.fwupd.enable = true;         # Firmware update tool for BIOS, etc...
  services.gvfs.enable = true;          # GVfs virtual filesystem

  # Optionally enable client nfs shares
  services.nfs.client.shares.enable = args.settings.nfs_shares;

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
    openvpn                             # An easy-to-use, robust and highly configurable VPN (Virtual Private Network)

    # Network
    freerdp                             # RDP client plugin for remmina
    remmina                             # Nice remoting UI for RDP and other protocols
    #tdesktop                            # Telegram Desktop messaging app
    vopono                              # Run applications through VPN connections in network namespaces
    update-systemd-resolved             # OpenVPN systemd-resolved updater
    zoom-us                             # Video conferencing application

    # Media
    asunder                             # A lean and friendly audio CD ripper and encoder
    audacious                           # Lightweight advanced audio player
    audacious-plugins                   # Additional codecs support for audacious
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
    qview                               # Simple image viewer with webp support
    #obs-studio                          # Free and open source software for video recording and live streaming
    simplescreenrecorder                # Awesome screen recorder
    vlc                                 # Multi-platform MPEG, VCD/DVD, and DivX player
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

    # Utilities
    alacritty                           # GPU accelerated terminal
    alacritty-theme                     # GPU accelerated terminal themes
    awf                                 # A widget factory for viewing theme changes
    conky                               # Advanced, highly configurable system monitor
    exiftool                            # A tool to read, write and edit EXIF meta information
    galculator                          # Simple calculator
    gnome-multi-writer                  # Tool for writing an ISO file to multiple USB devices at once
    htop                                # Better top tool
    hardinfo                            # A system information and benchmark tool
    light                               # Control backlights for screen and keyboard
    veracrypt                           # Free Open-Source filesystem encryption

    # System
    jdk17                               # Needed for: minecraft
  ];
}
