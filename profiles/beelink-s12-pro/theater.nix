# Theater configuration for beelink-s12-pro
#
# ### Features
# - Directly installable: generic/theater with additional hardware configuration
# - Working hardware accelerated video in Kodi as verified with 'intel_gpu_top'
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  imports = [
    ../../modules/hardware/intel-mini-pc.nix
    ../generic/theater.nix
  ];

  # Add additional packages
  # ------------------------------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
  ];
}
