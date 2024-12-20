# Theater configuration for acepc-ak1
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

  hardware.intel-graphics.enable = true;

  environment.systemPackages = with pkgs; [
  ];
}
