# Theater configuration for acepc-ak1
#
# ### Features
# - Directly installable: xfce/theater with additional hardware configuration
# - Working hardware accelerated video in Kodi as verified with 'intel_gpu_top'
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  imports = [
    ../../modules/hardware/intel-mini-pc.nix
    ../generic/desktop.nix
  ];

  # Add additional packages
  # ------------------------------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
  ];
}
