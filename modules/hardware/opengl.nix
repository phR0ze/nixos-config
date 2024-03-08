# OpenGL video configuration
#
# ### Detail
# - https://nixos.wiki/wiki/OpenGL
# - Mesa is an open source OpenGL, Vulkan and other 3D graphics specification. AMD uses Mesa's 
#   Radeon over the deprecated AMD Catalyst and Intel only uses Mesa. Nouveau also uses Mesa but
#   Proprietary Nvidia doesn't use any of Mesa.
# - test config with: `nix-shell -p libva-utils --run vainfo`
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  hardware.opengl = {
    enable = true;                      # Installs mesa, mesa_drivers, mesa-demos

    # Set by default see
    # - https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/opengl.nix
    driSupport = true;                  # Enable OpenGL rendering through DRI for Vulkan
    driSupport32Bit = true;             # Enabled by X11 by default
    package = pkgs.mesa.drivers;        # OpenGL implementation aliased with 'mesa_drivers'
    package32 = pkgs.pkgsi686Linux.mesa.drivers;  # OpenGL implementation aliased with 'mesa_drivers'

    #setLdLibraryPath = true;           # Drivers using dispatch libraries like libglvnd should not set this

    # Additional drivers e.g. VA-API/VDPAU
    extraPackages = with pkgs; [
      #intel-media-driver               # iHD, Use for Broadwell (2014) or newer
      #intel-vaapi-driver               # Use for older than Broadwell (2014), aliased with vaapiIntel
      #vaapiVdpau                       # 
      #libvdpau-va-gl                   #
#    vaapi-intel-hybrid
#    libva-full
#    libva-utils
    ];
    #extraPackages32 = with pkgs; [
    #];
  };

  environment.systemPackages = with pkgs; [
    mesa                                # Open-source 3D graphics library
    mesa_drivers                        # An open source 3D graphics library
    mesa-demos                          # Collection of demos and test programs for OpenGL and Mesa
  ];

#  environment.variables = {
#    VDPAU_DRIVER = "va_gl";
#    LIBVA_DRIVER_NAME = "iHD";         # Force intel-media-driver use
#    MOZ_DISABLE_RDD_SANDBOX = "1";
#  };

    #config = lib.mkAfter ''
    #'';

    # The first element is used as the default resolution
    #resolutions = [
    #  { x = 1920; y = 1080; }
    #];


    # Video drivers to be tried in order until one that supports your card is found
    # Default: modesetting, fbdev
    #videoDrivers = [
    #  "modesetting"
    #  "fbdev"
    #  "nvidia"
    #  "nvidiaLegacy390"
    #  "amdgpu-pro"
    #];

  # Intel iHD video configuration
  # - https://nixos.wiki/wiki/Accelerated_Video_Playback
  #-------------------------------------------------------------------------------------------------
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
  #-------------------------------------------------------------------------------------------------
  # Make the kernel use the correct driver early
  # boot.initrd.kernelModules = [ "amdgpu" ];
  # services.xserver.videoDrivers = [ "amdgpu" ];

  # Nvidia configuration
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
  #services.xserver.videoDrivers = [ "nvidia" ];


}
