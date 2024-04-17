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
  #services.xserver.xft.dpi = 192;
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

  # Add additional theater package
  environment.systemPackages = with pkgs; [ ];
}
