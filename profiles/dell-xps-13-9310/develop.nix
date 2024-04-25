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

  # Disable x11vnc for laptops
  services.x11vnc.enable = false;

  # Increase the dpi
  services.xserver.xft.dpi = 110;

  # Enable virtualbox host
  virtualisation.virtualbox.host.enable = true;

  # Add additional packages
  # ------------------------------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
  ];
}
