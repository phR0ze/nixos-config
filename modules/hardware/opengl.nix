# OpenGL video configuration
#
# ### Detail
# - Mesa is an open source OpenGL, Vulkan and other 3D graphics specification. AMD uses Mesa's 
#   Radeon over the deprecated AMD Catalyst and Intel only uses Mesa. Nouveau also uses Mesa but
#   Proprietary Nvidia doesn't use any of Mesa.
#
# ### Testing
# - OpenGL with: `glxgears`
# - VA-API with: `nix-shell -p libva-utils --run vainfo`
# - OpenCL with: `clinfo | head -n3`
# - Vulkan with: `vulkaninfo | grep GPU` or `vkcube`
#
# - https://nixos.wiki/wiki/OpenGL
# - https://nixos.org/manual/nixos/unstable/#sec-gpu-accel
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  # boot.kernelModules = mkBefore [ "kvm-intel" ];

  # OpenGL configuration
  #-------------------------------------------------------------------------------------------------
  hardware.opengl = {
    enable = true;                      # Installs mesa, mesa_drivers, mesa-demos
    driSupport = true;                  # Enable OpenGL rendering through DRI for Vulkan
    driSupport32Bit = true;             # Enabled by X11 by default
    package = pkgs.mesa.drivers;        # OpenGL implementation aliased with 'mesa_drivers'
    package32 = pkgs.pkgsi686Linux.mesa.drivers;  # OpenGL implementation aliased with 'mesa_drivers'

    #setLdLibraryPath = true;           # Drivers using libglvnd dispatch should not set this

    # Additional drivers e.g. VA-API/VDPAU
    extraPackages = with pkgs; [
      # AMD GPUs
      # rocmPackages.clr.icd            # OpenCL support for modern AMD GPUs
      # amdvlk                          # Vulkan support for Non-free driver, free is part of Mesa

      # Intel GPUs
      #intel-compute-runtime            # OpenCL support for Intel Gen 8 or newer
      #intel-ocl                        # OpenCL support for Intel Gen 7 or older
      #intel-media-driver               # VA-API support for Intel iHD Broadwell (2014) or newer
      #intel-vaapi-driver               # VA-API support for Intel i965 Broadwell (2014) or older aka vaapiIntel

      #vaapiVdpau                       # 
      #libvdpau-va-gl                   #
#    vaapi-intel-hybrid
#    libva-full
#    libva-utils
     #libglvnd                          # GL Vendor Neutral dispatch library
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      # AMD GPUs
      # rocmPackages.clr.icd            # OpenCL support for modern AMD GPUs
      # amdvlk                          # Vulkan support for Non-free driver, free is part of Mesa

      # Intel GPUs
      #intel-compute-runtime            # OpenCL support for Intel Gen 8 or newer
      #intel-ocl                        # OpenCL support for Intel Gen 7 or older
      #intel-media-driver               # VA-API support for Intel iHD Broadwell (2014) or newer
      #intel-vaapi-driver               # VA-API support for Intel i965 Broadwell (2014) or older aka vaapiIntel

      #intel-media-driver               # iHD, Use for Broadwell (2014) or newer
      #intel-vaapi-driver               # Use for older than Broadwell (2014), aliased with vaapiIntel
    ];
  };

  # Supporting system packages
  #-------------------------------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    mesa                                # Open-source 3D graphics library
    mesa_drivers                        # An open source 3D graphics library
    mesa-demos                          # Collection of demos and test programs for OpenGL and Mesa
    libva-utils                         # A collection of utilities and examples for VA-API e.g. vainfo
  ];

  # Video drivers to be tried in order until one that supports your card is found
  # - this is usually controlled by the different video package enable options
  # - default: modesetting, fbdev
  #-------------------------------------------------------------------------------------------------
  #services.xserver.videoDrivers = [
    #"virtualbox"                        # VirtualBox graphics driver
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

  # Nvidia configuration
  # - https://nixos.org/manual/nixos/unstable/#sec-x11-graphics-cards-nvidia
  #-------------------------------------------------------------------------------------------------
#  hardware.nvidia = {
#    prime = {
#      offload.enable = true;
#      offload.enableOffloadCmd = true;
#      nvidiaBusId = "PCI:1:0:0";
#      amdgpuBusId = "PCI:6:0:0";
#    };
#
#    modesetting.enable = true;
#
#    powerManagement = {
#      enable = true;
#      finegrained = true;
#    };
#
#    open = true;
#    nvidiaSettings = false; # gui app
#    package = config.boot.kernelPackages.nvidiaPackages.latest;
#  };
  # Non-free
  #services.xserver.videoDrivers = [ "nvidia" ];
  # older cards
  #services.xserver.videoDrivers = [ "nvidiaLegacy390" ];
  #services.xserver.videoDrivers = [ "nvidiaLegacy340" ];
  #services.xserver.videoDrivers = [ "nvidiaLegacy304" ];
}
