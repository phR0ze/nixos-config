# Nvidia graphics configuration
# - https://nixos.wiki/wiki/Nvidia
#
# ### Supported systems
# - GeForce GTX 1050 Ti
#   - stable, beta and production should work
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.hardware.nvidia-graphics;
  x11 = config.services.xserver;

in
{
  options = {
    hardware.nvidia-graphics = {
      enable = lib.mkEnableOption "Install and configure Nvidia graphics";
    };
  };

  config = lib.mkMerge [

    # Configure X11 video driver
    (lib.mkIf (cfg.enable && x11.enable) {
      services.xserver.videoDrivers = [ "nvidia" ];
      #services.xserver.videoDrivers = [ "nvidiaLegacy470" ];
      #services.xserver.videoDrivers = [ "nvidiaLegacy390" ];
      #services.xserver.videoDrivers = [ "nvidiaLegacy340" ];
    })

    # Have the kernel load the correct GPU driver as soon as possible
    (lib.mkIf (cfg.enable) {
      hardware.nvidia = {

        # Modesetting is required.
        modesetting.enable = true;

        # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
        # Enable this if you have graphical corruption issues or application crashes after waking
        # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
        # of just the bare essentials.
        powerManagement.enable = false;

        # Fine-grained power management. Turns off GPU when not in use.
        # Experimental and only works on modern Nvidia GPUs (Turing or newer).
        powerManagement.finegrained = false;

        # Use the NVidia open source kernel module (not to be confused with the
        # independent third-party "nouveau" open source driver).
        # Support is limited to the Turing and later architectures. Full list of 
        # supported GPUs is at: 
        # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
        # Only available from driver 515.43.04+
        # Currently alpha-quality/buggy, so false is currently the recommended setting.
        open = false;

        # Enable the Nvidia settings menu,
        # accessible via `nvidia-settings`.
        nvidiaSettings = true;

        # Optionally, you may need to select the appropriate driver version for your specific GPU.
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };
    })
  ];
}
