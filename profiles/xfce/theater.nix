# XFCE theater configuration
#
# ### Features
# - Directly installable: xfce/desktop with additional media apps and configuration
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./desktop.nix
  ];

  #services.xserver.resolutions = [ { x = 1920; y = 1080; } ];
  services.xserver.desktopManager.xfce.desktop.background = lib.mkForce
    "/run/current-system/sw/share/backgrounds/theater_curtains1.jpg";
  environment.systemPackages = with pkgs; [ ];
}
