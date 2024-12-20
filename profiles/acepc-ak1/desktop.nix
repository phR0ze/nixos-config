# Theater configuration for acepc-ak1
#
# ### Features
# - Directly installable: generic/desktop with additional hardware configuration
# - Working hardware accelerated video in Kodi as verified with 'intel_gpu_top'
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  imports = [
    ../desktop.nix
  ];

  hardware.intel-graphics.enable = true;

  environment.systemPackages = with pkgs; [
  ];
}
