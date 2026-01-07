# XFCE full desktop configuration
#
# ### Features
# - Directly installable: full general purpose desktop environment
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./base.nix
  ];

  # Enable apps
  apps.office.evince.enable = true;         # Document viewer for PDF, djvu, tiff, dvi, XPS, cbr, cbz, cb7, cbt
  apps.media.jellyfin.enable = true;        # Install Jellyfin media player
  apps.media.xnviewmp.enable = true;        # Versatile image viewer with lossless JPEG rotation
  apps.network.qbittorrent.enable = true;   # Excellent bittorrent client
  apps.system.veracrypt.enable = true;      # Free Open-Source filesystem encryption

  apps.games.steam.enable = true;           # Digital distribution platform from Valve
  apps.games.protontricks.enable = true;    # A simple wrapper for running Winetricks commands for Proton-enabled games
  apps.games.prismlauncher.enable = true;   # Minecraft launcher
  #apps.games.warcraft2.enable = true;      # Add firewall rules needed for warcraft 2 IPX LAN multi-player
  programs.winetricks.enable = true;        # A script to install DLLs needed to work around problems in Wine

  # Enable services
  services.raw.rustdesk.enable = true;      # Simple fast remote desktop solution

  # Additional apps
  environment.systemPackages = with pkgs; [
    zoom-us                   # Video conferencing application

    # Media
    asunder                   # A lean and friendly audio CD ripper and encoder
    audacious                 # Lightweight advanced audio player
    audacious-plugins         # Additional codecs support for audacious
    audacity                  # Audio editor - cross platform, tried and tested
    brasero                   # Burning tool, alt: k3b, xfburn
    devede                    # A program to create VideoDVDs and CDs
    cheese                    # Take photos and videos with your webcam, with fun graphical effects
    dvdbackup                 # Command line tool for ripping DVDs
    gimp                      # Excellent image editor
    inkscape                  # Vector graphics editor
    flac                      # Free lossless audio codec
    kdePackages.kolourpaint   # Paint application that saves jpg in format for GFXBoot
    libdvdcss                 # DVD decrypting media codec support
    losslesscut-bin           # Crossplatform GUI tool for lossless trimming/cuttong of video/audio files
    handbrake                 # Video encoding tool for mp4/mkv
    lame                      # High quality MPEG layer III audio encoder
    mkvtoolnix                # Cross-platform tools for Matroska
    mpv                       # General purpose media player, fork of MPlayer and mplayer2
    kdePackages.kdenlive      # Reliable, intuitive Video editor. OpenShot is buggy and kept having problems
    #obs-studio               # Free and open source software for video recording and live streaming
    simplescreenrecorder      # Awesome screen recorder
    vlc                       # Multi-platform MPEG, VCD/DVD, and DivX player
    x264                      # Open Source H264/AVC video encoder, depof: smplayer
    yt-dlp                    # Command-line tool to download videos from YouTube.com and other sites

    # Game
    #cartridges               # A GTK4 + Libadwaita game launcher
    lutris                    # Open Source gaming platform for GNU/Linux

    # Office
    hunspell                  # LibreOffice spell checker and actively maintained
    hunspellDicts.en_US       # LibreOffice spell checker and actively maintained
    libreoffice-fresh         # Comprehensive, professional-quality productivity suite
    scribus                   # Open Source Desktop Publishing

    # Utilities
    kdePackages.filelight     # View disk usage information
    awf                       # A widget factory for viewing theme changes
  ];
}
