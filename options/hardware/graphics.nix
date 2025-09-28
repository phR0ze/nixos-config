# Graphics configuration
#
# ### Supported systems
# - AMD Lexa PRO
#
# ### Research
# - https://wiki.archlinux.org/title/Hardware_video_acceleration
# - https://wiki.archlinux.org/title/Hardware_video_acceleration#Comparison_tables
#
# ### Background
# There are are few different hardware accelerated video APIs: VA-API and VDPAU are the most common:
# - Video Acceleration API (VA-API) is a specification developed by Intel for both hardware 
#   accelerated video encoding and decoding. Much more widely supported than VDPAU.
# - Video Decode and Presentation API for Unix (VDPAU) is an open source library and API to offload 
#   portions of the video decoding process and video post-processing to the GPU developed by Nvidia.
#   Primarily used by Nvidia cards and has limited support in applications.
#
# - Mesa is an open source implementation for the various API specifications including VA-API, VDPAU, 
#   OpenGL, Vulkan, OpenCL and other 3D graphics specification. AMD, Intel and Nouveau all use Mesa, 
#   but Nvidia's proprietary driver doesn't.
#
# ### Discovery
# 1. Determmine your Video card with `lspci | grep VGA`
#
# ### General config steps
# 1. Make the kernel use the correct driver early
#    boot.kernelModules = lib.mkForce [ "kvm-intel" ];
#    boot.initrd.kernelModules = [ "amdgpu" ];
#
# 2. Make Xserver use the correct driver e.g.
#    services.xserver.videoDrivers = [ "amdgpu" ];
#
# ### Testing
# - OpenGL with: `glxgears`
# - Check VA-API support: `nix-shell -p libva-utils --run vainfo`
# - OpenCL with: `clinfo | head -n3`
# - Vulkan with: `vulkaninfo | grep GPU` or `vkcube`
#
# - https://nixos.wiki/wiki/OpenGL
# - https://nixos.org/manual/nixos/unstable/#sec-gpu-accel

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

    # Common configuration
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (x11.enable) {
      hardware.graphics = {
        enable = true;                      # Installs mesa, mesa drivers, mesa-demos
        enable32Bit = true;

        # Defaults from the opengl option, also aliased with 'mesa_drivers'
        package = pkgs.mesa;
        package32 = pkgs.pkgsi686Linux.mesa;
      };

      # Supporting system packages
      #-------------------------------------------------------------------------------------------------
      environment.systemPackages = with pkgs; [
        libva-utils                 # A collection of utilities and examples for VA-API e.g. vainfo
        mesa                        # Open-source 3D graphics library
        mesa-demos                  # Collection of demos and test programs for OpenGL and Mesa
        pciutils                    # Collection of utilities for inspecting and manipulating PCI devices
        vdpauinfo                   # Tool to query the Video Decode and Presentation API (VDPAU)

        # Doesn't seem to recognize the GPU even exists
        #nvtop                      # A (h)top like task monitor for AMD, Adreno, Intel and NVIDIA
      ];
    })

    # AMD graphics
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf cfg.amd {
      # Have the kernel load the correct GPU driver as soon as possible
      boot.initrd.kernelModules = [ "amdgpu" ];
    })
    (lib.mkIf (cfg.amd && x11.enable) {
      services.xserver.videoDrivers = [ "amdgpu" ];
    })

    # Intel graphics
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf cfg.intel {
      hardware.graphics.extraPackages = with pkgs; [
        intel-media-driver          # VA-API for Intel iHD Broadwell (2014) or newer
        intel-vaapi-driver          # VA-API for Intel i965 Broadwell (2014), better for Firefox?
        vaapiVdpau                  # VDPAU driver for the VAAPI library
        libvdpau-va-gl              # VDPAU driver with OpenGL/VAAPI backend
      ];
      environment.systemPackages = with pkgs; [
        intel-gpu-tools
      ];
    })

    # Nvidia graphics
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf cfg.nvidia {
      # Have the kernel load the correct GPU driver as soon as possible
      hardware.nvidia = {
        modesetting.enable = true;  # Modesetting is required.

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
    (lib.mkIf (cfg.nvidia && x11.enable) {
      services.xserver.videoDrivers = [ "nvidia" ];
      #services.xserver.videoDrivers = [ "nvidiaLegacy470" ];
      #services.xserver.videoDrivers = [ "nvidiaLegacy390" ];
      #services.xserver.videoDrivers = [ "nvidiaLegacy340" ];
    })
  ];
}
