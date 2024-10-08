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
    ../../modules/virtualization/docker.nix
  ];

  hardware.amd-graphics.enable = true;
  services.barriers.enable = true;
  programs.freecad.enable = true;
  virtualization.virt-manager.enable = true;

  programs.xnviewmp.enable = true;

  environment.systemPackages = [
    pkgs.freetube
  ];
}
