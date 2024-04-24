# Theater configuration for acepc-ak1
#
# ### Features
# - Directly installable: generic/desktop with additional hardware configuration
# - Working hardware accelerated video in Kodi as verified with 'intel_gpu_top'
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  imports = [
    ../../modules/hardware/intel-graphics.nix
    ../generic/desktop.nix
  ];

  # Add additional packages
  # ------------------------------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
  ];
}
