# Theater configuration for Dell XPS 13 9310
#
# ### Features
# - Directly installable: generic/develop with Intel hardware support
# - Working hardware accelerated video in Kodi as verified with 'intel_gpu_top'
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  imports = [
    ../generic/develop.nix
  ];

  hardware.intel-graphics.enable = true;
  services.xserver.xft.dpi = 110;
  services.x11vnc.enable = lib.mkForce false;

  virtualization.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
  ];
}
