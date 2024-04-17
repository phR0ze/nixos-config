# XFCE theater configuration
#
# ### Features
# - Directly installable: xfce/desktop with additional media apps and configuration
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
let
  backgrounds = pkgs.callPackage ../../modules/desktop/backgrounds { };

in
{
  imports = [
    ./desktop.nix
  ];

  # High dpi settings
  services.xserver.xft.dpi = 130;
  services.xserver.desktopManager.xfce.panel.taskbar.size = 36;
  services.xserver.desktopManager.xfce.panel.taskbar.iconSize = 32;
  services.xserver.desktopManager.xfce.panel.launcher.size = 52;
  #services.xserver.xft.sansSize = 18;
  #services.xserver.xft.serifSize = 18;
  #services.xserver.xft.monospaceSize = 18;
  #services.xserver.xft.cursorSize = 64;

  # Configure theater system resolution default
  services.xserver.desktopManager.xfce.defaultDisplay.resolution = { x = 1920; y = 1080; };

  # Configure theater system background
  services.xserver.desktopManager.xfce.desktop.background = lib.mkOverride 500
    "/run/current-system/sw/share/backgrounds/theater_curtains1.jpg";

  # Set the default background image to avoid initial boot changes
  services.xserver.displayManager.lightdm.background = lib.mkOverride 500
    "${backgrounds}/share/backgrounds/theater_curtains1.jpg";

  # Set xfce launchers
  services.xserver.desktopManager.xfce.panel.launchers = [
    { name = "Xfce4 Terminal"; exec = "xfce4-terminal"; icon = "org.xfce.terminalemulator"; }
    { name = "Thunar"; exec = "exo-open --launch FileManager"; icon = "org.xfce.thunar"; }
    { name = "XnviewMP"; exec = "xnviewmp"; icon = "xnviewmp"; }
    { name = "Kodi"; exec = "kodi"; icon = "kodxnviewmpi"; }
    { name = "SMPlayer"; exec = "smplayer"; icon = "smplayer"; }
    { name = "HandBrake"; exec = "ghb"; icon = "fr.handbrake.ghb"; }
    { name = "VLC Media Player"; exec = "vlc"; icon = "vlc"; }
    { name = "FileZilla"; exec = "filezilla"; icon = "filezilla"; }
    { name = "Firefox"; exec = "firefox"; icon = "firefox"; }
    { name = "LibreOffice Calc"; exec = "libreoffice --calc"; icon = "libreoffice-calc"; }
    { name = "LibreOffice Writer"; exec = "libreoffice --writer"; icon = "libreoffice-writer"; }
  ];

  # Add additional theater package
  environment.systemPackages = with pkgs; [ ];
}
