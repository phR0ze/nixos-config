# XFCE theater configuration
#
# ### Features
# - Directly installable: desktop with additional media apps and configuration
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  imports = [
    ./desktop.nix
  ];

  machine.type.theater = true;

  # High dpi settings
  services.xserver.xft.dpi = 120; # 25% higher recommended by Arch Linux
  services.xserver.desktopManager.xfce.panel.taskbar.size = 36;
  services.xserver.desktopManager.xfce.panel.taskbar.iconSize = 32;
  services.xserver.desktopManager.xfce.panel.launcher.size = 52;

  # Display configuration
  machine.resolution = { x = 1920; y = 1080; };
  services.xserver.desktopManager.xfce.displays.connectingDisplay = 0;

  # Configure theater system background
  services.xserver.desktopManager.xfce.desktop.background = lib.mkOverride 500
    "/run/current-system/sw/share/backgrounds/theater_curtains1.jpg";

  # Set the default background image to avoid initial boot changes
  services.xserver.displayManager.lightdm.background = lib.mkOverride 500
    "${pkgs.desktop-assets}/share/backgrounds/theater_curtains1.jpg";

  # Configure Kodi
  programs.kodi = {
    enable = true;
    remoteControlHTTP = true;
  };

  # Add additional theater package
  environment.systemPackages = with pkgs; [ ];
}
