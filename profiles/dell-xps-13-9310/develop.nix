# Develop configuration for Dell XPS 13 9310
#
# ### Features
# - Directly installable: generic/develop with Intel hardware support
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  imports = [
    ../generic/develop.nix
  ];

  hardware.intel-graphics.enable = true;
  services.xserver.xft.dpi = 115;
  services.x11vnc.enable = lib.mkForce false;
  virtualization.virt-manager.enable = true;
}
