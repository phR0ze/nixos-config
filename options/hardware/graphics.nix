# AMD graphics configuration
#
# ### Supported systems
# - AMD Lexa PRO
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.hardware.graphics;
  x11 = config.services.xserver;
in
{
  options = {
    hardware.graphics = {
      amd = lib.mkEnableOption "Install and configure AMD graphics";
      intel = lib.mkEnableOption "Install and configure Intel graphics";
      nvidia = lib.mkEnableOption "Install and configure Nvidia graphics";
    };
  };

  config = lib.mkMerge [

    # AMD graphics
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf cfg.amd {
      # Have the kernel load the correct GPU driver as soon as possible
      boot.initrd.kernelModules = [ "amdgpu" ];
    })
    (lib.mkIf (cfg.amd && x11.enable) {
      # Configure X11 video driver
      services.xserver.videoDrivers = [ "amdgpu" ];
    })

    # Intel graphics
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf cfg.intel {
      hardware.opengl.extraPackages = with pkgs; [
        intel-media-driver          # VA-API for Intel iHD Broadwell (2014) or newer
        intel-vaapi-driver          # VA-API for Intel i965 Broadwell (2014), better for Firefox?
        vaapiVdpau                  # VDPAU driver for the VAAPI library
        libvdpau-va-gl              # VDPAU driver with OpenGL/VAAPI backend
      ];
      environment.systemPackages = with pkgs; [
        intel-gpu-tools
      ];
    });

    # Nvidia graphics
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.nvidia && x11.enable) {
      # Configure X11 video driver
      services.xserver.videoDrivers = [ "nvidia" ];
      #services.xserver.videoDrivers = [ "nvidiaLegacy470" ];
      #services.xserver.videoDrivers = [ "nvidiaLegacy390" ];
      #services.xserver.videoDrivers = [ "nvidiaLegacy340" ];
    })
    (lib.mkIf cfg.nvidia {
      # Have the kernel load the correct GPU driver as soon as possible
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
        # Support is limited to the Turing and later architectures. Full list of supported GPUs is at: 
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
