# XFCE minimal configuration
#
# ### Features
# - Directly installable: cli/default with bare minimal xfce environment
# - Size: 4504.7 MiB
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ../x11/minimal.nix
  ];

  # Installs xfce4-power-manager
  powerManagement.enable = true;

  # XFCE configuration
  # ------------------------------------------------------------------------------------------------
  services.xserver = {
    desktopManager = {
      xfce.enable = true;
      xfce.enableXfwm = true;
      xfce.enableScreensaver = true;
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
    galculator                        # Simple calculator
    gnome.gnome-themes-extra          # Xfce default,
    gnome.adwaita-icon-theme          # Xfce default,
    hicolor-icon-theme                # Xfce default,
    tango-icon-theme                  # Xfce default,
    desktop-file-utils                # Xfce default,
    shared-mime-info                  # Xfce default, for update-mime-database
    polkit_gnome                      # Xfce default, polkit authentication agent
    parole                            # Xfce default, simple media player
    ristretto                         # Xfce default, simple picture viewer
    xfce4-appfinder                   # Xfce default
    xfce4-screenshooter               # Xfce default, plugin that makes screenshots for Xfce
    xfce4-taskmanager                 # Xfce default
    xfce4-terminal                    # Xfce default
  ];

  environment.xfce.excludePackages = with pkgs.xfce // pkgs; [
    mousepad                          # Xfce default, simple text editor
  ];
}
