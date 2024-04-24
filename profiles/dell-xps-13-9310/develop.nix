# Theater configuration for Dell XPS 13 9310
#
# ### Features
# - Directly installable: generic/develop with Intel hardware support
# - Working hardware accelerated video in Kodi as verified with 'intel_gpu_top'
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  imports = [
    ../../modules/hardware/intel-graphics.nix
    ../generic/develop.nix
  ];

  # Add additional packages
  # ------------------------------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
  ];
}
