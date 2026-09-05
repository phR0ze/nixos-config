# XFCE theater configuration
#
# ### Features
# - Desktop with additional media apps/configs
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  host.type.theater = true;

  # High dpi settings
  system.x11.xft.dpi = 120; # 25% higher recommended by Arch Linux
  system.xfce.panel.taskbar.size = 36;
  system.xfce.panel.taskbar.iconSize = 32;
  system.xfce.panel.launcher.size = 52;

  # Display configuration
  host.resolution = { x = 1920; y = 1080; };
  system.xfce.displays.connectingDisplay = 0;

  # Configure theater system background
  system.xfce.desktop.background = "${pkgs.desktop-assets}/share/backgrounds/theater_curtains1.jpg";

  # Add additional theater package
  environment.systemPackages = [
    # pkgs.
  ];
}
