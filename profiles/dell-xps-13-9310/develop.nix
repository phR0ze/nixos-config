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
    ../../modules/hardware/intel-graphics.nix
    ../../modules/virtualization/boxes.nix
  ];

  # Enable minecraft server for testing
  services.minecraft-server.enable = true;

  # Disable x11vnc for laptops
  services.x11vnc.enable = false;

  # Increase the dpi
  services.xserver.xft.dpi = 110;

  # Enable boxes virtualization
  virtualisation.boxes.enable = true;

  # Add additional packages
  # ------------------------------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
  ];
}
