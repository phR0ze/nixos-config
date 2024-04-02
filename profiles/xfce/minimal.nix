# XFCE minimal configuration
#
# ### Features
# - Directly installable: cli/default with bare minimal xfce environment
# - Size: 4504.7 MiB
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  imports = [
    ../x11/minimal.nix
  ];

  # Enable the main configuration tool for xfce and drop in custom configuration
  programs.xfconf.enable = true;
  #files.all.".config/xfce4/xfconf".copy = ../../include/home/.config/xfce4/xfconf;
  files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml".copy = 
    ../../include/home/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml;

  # Indirectly installs xfce4-power-manager
  powerManagement.enable = true;

  # XFCE configuration
  # ------------------------------------------------------------------------------------------------
  services.xserver = {
    desktopManager = {
      xfce.enable = true;
      xfce.enableXfwm = true;
      xfce.enableScreensaver = true;
      xfce.xfce4-desktop.background = lib.mkDefault "/usr/share/backgrounds/theater_curtains1.jpg";
    };
    displayManager = {
      defaultSession = "xfce";
    };
  };

  # Additional xfce specific services
  services.tumbler.enable = true;     # tumbler uses ffmpegthumbnailer

  # Thunar configuration
  # ------------------------------------------------------------------------------------------------
  programs.thunar.plugins = with pkgs.xfce; [
    thunar-volman
    thunar-archive-plugin
    thunar-media-tags-plugin
  ];
  
  # General applications
  # ------------------------------------------------------------------------------------------------
  environment.systemPackages = with pkgs.xfce // pkgs; [
    gnome.gnome-themes-extra          # Xfce default,
    gnome.adwaita-icon-theme          # Xfce default,
    hicolor-icon-theme                # Xfce default,
    desktop-file-utils                # Xfce default,
    shared-mime-info                  # Xfce default, for update-mime-database
    polkit_gnome                      # Xfce default, polkit authentication agent
    ristretto                         # Xfce default, simple picture viewer
    xfce4-appfinder                   # Xfce default
    xfce4-screenshooter               # Xfce default, plugin that makes screenshots for Xfce
    xfce4-taskmanager                 # Xfce default
    xfce4-terminal                    # Xfce default
  ];

  environment.xfce.excludePackages = with pkgs.xfce // pkgs; [
    tango-icon-theme                  # Xfce default,
    mousepad                          # Xfce default, simple text editor
    parole                            # Xfce default, simple media player
  ];
}
