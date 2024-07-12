# Theater configuration for beelink-s12-pro
#
# ### Features
# - Directly installable: generic/theater with additional hardware configuration
# - Working hardware accelerated video in Kodi as verified with 'intel_gpu_top'
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  imports = [
    ../generic/theater.nix
  ];

  hardware.intel-graphics.enable = true;

  programs.kodi = {
    enble = true;
    remoteControlHTTP = true;
  };

  environment.systemPackages = with pkgs; [
  ];
}
