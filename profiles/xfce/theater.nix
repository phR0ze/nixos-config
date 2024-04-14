# XFCE theater configuration
#
# ### Features
# - Directly installable: xfce/desktop with additional media apps and configuration
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  imports = [
    ./desktop.nix
  ];

  # Configure theater system resolution default
  services.xserver.desktopManager.xfce.defaultDisplay.resolution = { x = 1920; y = 1080; };

  # Configure theater system background
  services.xserver.desktopManager.xfce.desktop.background = lib.mkOverride 500
    "/run/current-system/sw/share/backgrounds/theater_curtains1.jpg";

  # Todo convert backgrounds into a pkg that can be called and made reusable
  #services.xserver.displayManager.lightdm.background = "${backgroundsPackage}/share/backgrounds/sector-8_1600x900.jpg";

  # Add additional theater package
  environment.systemPackages = with pkgs; [ ];
}
