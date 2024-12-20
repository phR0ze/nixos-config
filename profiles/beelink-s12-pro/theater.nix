# Theater configuration for beelink-s12-pro
#
# ### Features
# - Directly installable: generic/theater with additional hardware configuration
# - Working hardware accelerated video in Kodi as verified with 'intel_gpu_top'
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  imports = [
    ../theater.nix
  ];

  # Hardware
  hardware.intel-graphics.enable = true;

  # Games
  programs.hedgewars.enable = true;
  programs.superTuxKart.enable = true;

  # Misc programs
  environment.systemPackages = with pkgs; [
  ];
}
