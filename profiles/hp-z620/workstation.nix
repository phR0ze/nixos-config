# Workstation configuration for HP Z620
#
# ### Features
# - Directly installable: generic/develop with AMD GPU support
# - barrier server configuration
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  imports = [
    ../generic/develop.nix
  ];

  hardware.amd-graphics.enable = true;
  services.barriers.enable = true;

  #virtualization.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    freecad
  ];
  services.xserver.desktopManager.xfce.menu.overrides = [
    { source = "${pkgs.freecad}/share/applications/org.freecadweb.FreeCAD.desktop"; categories = "Graphics"; }
  ];
}
