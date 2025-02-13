# XFCE full desktop configuration
#
# ### Features
# - Directly installable: full general purpose desktop environment
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./light.nix
  ];

  apps.games.steam.enable = true;           # Digital distribution platform from Valve
  apps.games.protontricks.enable = true;    # A simple wrapper for running Winetricks commands for Proton-enabled games
  apps.games.prismlauncher.enable = true;   # Minecraft launcher
  #apps.games.warcraft2.enable = true;      # Add firewall rules needed for warcraft 2 IPX LAN multi-player
  programs.winetricks.enable = true;        # A script to install DLLs needed to work around problems in Wine
  apps.network.qbittorrent.enable = true;   # Excellent bittorrent client

  # Multimedia
  apps.media.kodi = {                       # Media player and entertainment hub
    enable = true;
    remoteControlHTTP = true;
  };

  environment.systemPackages = with pkgs; [

    # Network
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
    kolourpaint               # Paint application that saves jpg in format for GFXBoot
    libdvdcss                 # DVD decrypting media codec support
    losslesscut-bin           # Crossplatform GUI tool for lossless trimming/cuttong of video/audio files
    lxdvdrip                  # Command line tool for ripping, shrinking and burning DVDs 
    handbrake                 # Video encoding tool for mp4/mkv
    lame                      # High quality MPEG layer III audio encoder
    mkvtoolnix                # Cross-platform tools for Matroska
    mpv                       # General purpose media player, fork of MPlayer and mplayer2
    openshot-qt               # Simple powerful Video Editor, alt: pitivi, kdenlive
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
    awf                       # A widget factory for viewing theme changes
  ];
}
