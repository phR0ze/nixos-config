# Develop configuration for Dell XPS 13 9310
#
# ### Features
# - Directly installable: generic/develop with Intel hardware support
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  imports = [
    ../xfce/develop.nix
  ];

  hardware.graphics.intel = true;
  services.xserver.xft.dpi = 115;
  virtualization.qemu.host.enable = true;
  services.x11vnc.enable = lib.mkForce false;
}
