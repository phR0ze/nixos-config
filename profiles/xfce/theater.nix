# XFCE theater configuration
#
# ### Features
# - Directly installable: xfce/desktop with additional media apps and configuration
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
let
  backgrounds = callPackage ../../modules/desktop/backgrounds/pkg.nix { };

in
{
  imports = [
    ./desktop.nix
  ];

  # Configure theater system resolution default
  services.xserver.desktopManager.xfce.defaultDisplay.resolution = { x = 1920; y = 1080; };

  # Configure theater system background
  services.xserver.desktopManager.xfce.desktop.background = lib.mkOverride 500
    "/run/current-system/sw/share/backgrounds/theater_curtains1.jpg";

  # Set the default background image to avoid initial boot changes
  services.xserver.displayManager.lightdm.background = lib.mkOverride 500
    "${backgrounds}/share/backgrounds/theater_curtains1.jpg";

  # Add additional theater package
  environment.systemPackages = with pkgs; [ ];
}
