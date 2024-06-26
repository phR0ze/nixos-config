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
  programs.freecad.enable = true;
  virtualization.virt-manager.enable = true;
}
