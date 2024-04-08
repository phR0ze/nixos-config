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

  services.xserver = {
    displayManager = {
      defaultSession = "xfce";
    };
    desktopManager = {
      xfce.enable = true;
      xfce.enableXfwm = true;
      xfce.enableScreensaver = true;
      xfce.keyboards.enable = true;
      xfce.thunar.enable = true;
      xfce.xsettings.enable = true;
      xfce.panel.enable = true;
      xfce.powerManager.enable = true;
      xfce.desktop.background = lib.mkDefault "/run/current-system/sw/share/backgrounds/theater_curtains1.jpg";
      xfce.panel.launchers = [
        { name = "Xfce4 Terminal"; exec = "xfce4-terminal"; icon = "org.xfce.terminalemulator"; }
        { name = "Thunar"; exec = "exo-open --launch FileManager"; icon = "org.xfce.thunar"; }
        { name = "SMPlayer"; exec = "smplayer"; icon = "smplayer"; }
        { name = "HandBrake"; exec = "ghb"; icon = "fr.handbrake.ghb"; }
        { name = "VLC Media Player"; exec = "vlc"; icon = "vlc"; }
        { name = "FileZilla"; exec = "filezilla"; icon = "filezilla"; }
        { name = "Firefox"; exec = "firefox"; icon = "firefox"; }
        { name = "LibreOffice Calc"; exec = "libreoffice --calc"; icon = "libreoffice-calc"; }
        { name = "LibreOffice Writer"; exec = "libreoffice --writer"; icon = "libreoffice-writer"; }
        { name = "VirtualBox"; exec = "VirtualBox"; icon = "virtualbox"; }
      ];
    };
  };

  programs.xfconf.enable = true;            # Enable XFCE's configuration manager
  
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
