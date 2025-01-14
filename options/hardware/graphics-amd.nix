# AMD graphics configuration
#
# ### Supported systems
# - AMD Lexa PRO
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.hardware.amd-graphics;
  x11 = config.services.xserver;

in
{
  options = {
    hardware.amd-graphics = {
      enable = lib.mkEnableOption "Install and configure AMD graphics";
    };
  };

  config = lib.mkMerge [

    # Have the kernel load the correct GPU driver as soon as possible
    (lib.mkIf (cfg.enable) {
      boot.initrd.kernelModules = [ "amdgpu" ];
    })

    # Configure X11 video driver
    (lib.mkIf (cfg.enable && x11.enable) {
      services.xserver.videoDrivers = [ "amdgpu" ];
    })
  ];
}
