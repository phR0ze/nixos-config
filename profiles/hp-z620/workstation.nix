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

  # Hardware
  hardware.amd-graphics.enable = true;

  # Services
  services.barriers.enable = true;

  # Utilities
  programs.freecad.enable = true;
  virtualization.virt-manager.enable = true;

  # Games
  programs.hedgewars.enable = true;
  programs.superTuxKart.enable = true;

  # Multimedia
  programs.xnviewmp.enable = true;
  environment.systemPackages = [
    pkgs.freetube
  ];
}
