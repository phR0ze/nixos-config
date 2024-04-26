# Intel graphics configuration
#
# ### Supported systems
# - acepc-ak1
# - beelink-s12-pro
# - dell-xps-13
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.hardware.intel-graphics;
  
in
{
  options = {
    hardware.intel-graphics = {
      enable = lib.mkEnableOption "Install and configure Intel graphics";
    };
  };
 
  config = lib.mkIf (cfg.enable) {

    hardware.opengl.extraPackages = with pkgs; [
      intel-media-driver          # VA-API for Intel iHD Broadwell (2014) or newer
      intel-vaapi-driver          # VA-API for Intel i965 Broadwell (2014), better for Firefox?
      vaapiVdpau                  # VDPAU driver for the VAAPI library
      libvdpau-va-gl              # VDPAU driver with OpenGL/VAAPI backend
    ];

    environment.systemPackages = with pkgs; [
      intel-gpu-tools
    ];
  };
}
