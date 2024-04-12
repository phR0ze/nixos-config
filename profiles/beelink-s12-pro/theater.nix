# Theater configuration for beelink-s12-pro
#
# ### Features
# - Directly installable: xfce/theater with additional hardware configuration
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  imports = [
    ../xfce/theater.nix
  ];

  # OpenGL hardware specific configuration
  # ------------------------------------------------------------------------------------------------

  # Already exists in hardware-configuration.nix per NixOS installation detection but including here
  # so that I'm reminded as to its importance in the video configuration aspect of the beelink-s12
  boot.kernelModules = lib.mkForce [ "kvm-intel" ];

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
 
  # Add additional packages
  # ------------------------------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
  ];
}
