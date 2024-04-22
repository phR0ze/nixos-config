# Intel mini pc hardware configuration
#
# ### Supported systems
# - acepc-ak1
# - beelink-s12-pro
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  # OpenGL hardware specific configuration
  # ------------------------------------------------------------------------------------------------

  # Already exists in hardware-configuration.nix per NixOS installation detection but including here
  # so that I'm reminded as to its importance in the video configuration aspect of the beelink-s12
  boot.kernelModules = lib.mkForce [ "kvm-intel" ];

  hardware.opengl.extraPackages = with pkgs; [
    intel-media-driver          # VA-API for Intel iHD Broadwell (2014) or newer
    intel-vaapi-driver          # VA-API for Intel i965 Broadwell (2014), better for Firefox?
    vaapiVdpau                  # VDPAU driver for the VAAPI library
    libvdpau-va-gl              # VDPAU driver with OpenGL/VAAPI backend
  ];

  # Add additional packages
  # ------------------------------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    intel-gpu-tools
  ];
}
