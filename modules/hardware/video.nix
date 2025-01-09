# Hardware video acceleration configuration
#
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
# 2. Make Xserver use the correct driver
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
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  # Graphics configuration
  #-------------------------------------------------------------------------------------------------
  hardware.graphics = {
    enable = true;                      # Installs mesa, mesa_drivers, mesa-demos

    # Defaults from the opengl option, also aliased with 'mesa_drivers'
    package = pkgs.mesa.drivers;
    package32 = pkgs.pkgsi686Linux.mesa.drivers;

    #setLdLibraryPath = true;           # Drivers using libglvnd dispatch should not set this

    # Additional drivers e.g. VA-API/VDPAU
    extraPackages = with pkgs; [
      # AMD GPUs
      # rocmPackages.clr.icd            # OpenCL for modern AMD GPUs
      # amdvlk                          # Vulkan for Non-free driver, free is part of Mesa

      # Intel GPUs
      #intel-compute-runtime            # OpenCL for Intel Gen 8 or newer
      #intel-ocl                        # OpenCL for Intel Gen 7 or older
      #intel-media-driver               # VA-API for Intel iHD Broadwell (2014) or newer
      #intel-vaapi-driver               # VA-API for Intel i965 Broadwell (2014), alias 'vaapiIntel'

      #vaapiVdpau                       # 
      #libvdpau-va-gl                   #
#    vaapi-intel-hybrid
#    libva-full
     #libglvnd                          # GL Vendor Neutral dispatch library
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      # AMD GPUs
      # rocmPackages.clr.icd            # OpenCL for modern AMD GPUs
      # amdvlk                          # Vulkan for Non-free driver, free is part of Mesa

      # Intel GPUs
      #intel-compute-runtime            # OpenCL for Intel Gen 8 or newer
      #intel-ocl                        # OpenCL for Intel Gen 7 or older
      #intel-media-driver               # VA-API for Intel iHD Broadwell (2014) or newer
      #intel-vaapi-driver               # VA-API for Intel i965 Broadwell (2014), alias 'vaapiIntel'
    ];
  };

  # Supporting system packages
  #-------------------------------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    libva-utils                         # A collection of utilities and examples for VA-API e.g. vainfo
    mesa                                # Open-source 3D graphics library
    mesa.drivers                        # An open source 3D graphics library
    mesa-demos                          # Collection of demos and test programs for OpenGL and Mesa
    pciutils                            # Collection of utilities for inspecting and manipulating PCI devices
    vdpauinfo                           # Tool to query the Video Decode and Presentation API (VDPAU)

    # Doesn't seem to recognize the GPU even exists
    #nvtop                              # A (h)top like task monitor for AMD, Adreno, Intel and NVIDIA

    # Doesn't show hardware decoding usage only general usage
    #radeontop                           # Top-like tool for viewing AMD Radeon GPU utilization
  ];

  # Video drivers to be tried in order until one that supports your card is found
  # - this is usually controlled by the different video package enable options
  # - default: modesetting, fbdev
  #-------------------------------------------------------------------------------------------------
  #services.xserver.videoDrivers = [
    #"modesetting"
    #"fbdev"
    #"nvidia"
    #"nvidiaLegacy390"
    #"amdgpu"                            # Free AMD driver
    #"amdgpu-pro"                        # Proprietary AMD driver
  #];

#  environment.variables = {
#    VDPAU_DRIVER = "va_gl";
#    LIBVA_DRIVER_NAME = "iHD";         # Force intel-media-driver use
#    MOZ_DISABLE_RDD_SANDBOX = "1";
#  };

    #config = lib.mkAfter ''
    #'';

  #-------------------------------------------------------------------------------------------------
  # Intel
  # Intel iHD video configuration
  # - https://nixos.org/manual/nixos/unstable/#sec-x11--graphics-cards-intel
  # - https://nixos.wiki/wiki/Accelerated_Video_Playback
  #-------------------------------------------------------------------------------------------------
  # There are two choices for X.org for intel `modesetting` and `intel`. The recommendation is to
  # the modesetting option but if you have issues fallback on intel.
  #services.xserver.videoDrivers = [ "modesetting" ];
  # OR fallback
  #services.xserver.videoDrivers = [ "intel" ];
  #services.xserver.deviceSection = ''
  # Option "DRI" "2"
  # Option "TearFree" "true"
  #'';

#  nixpkgs.config.packageOverrides = pkgs: {
#    intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
#  };
#  hardware.opengl = {
#    enable = true;
#    extraPackages = with pkgs; [
#      intel-media-driver                # iHD
#      vaapiIntel                        # i965 vaapiIntel is an alias of this
#      vaapiVdpau                        #
#      libvdpau-va-gl                    #
#    ];
#  };
#  environment.sessionVariables = { LIBVA_DRIVER_NAME = "iHD"; }; # Force intel-media-driver
#  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ intel-vaapi-driver ];

  # AMD configuration
  # - https://nixos.wiki/wiki/AMD_GPU
  # - https://nixos.org/manual/nixos/unstable/#sec-x11--graphics-cards-amd
  #-------------------------------------------------------------------------------------------------
  # Make the kernel use the correct driver early
  # boot.initrd.kernelModules = [ "amdgpu" ];
  # Free
  # services.xserver.videoDrivers = [ "amdgpu" ];
  # Non-free 
  # services.xserver.videoDrivers = [ "amdgpu-pro" ];
}
