# Theater configuration for beelink-s12-pro
#
# ### Features
# - Directly installable: xfce/theater with additional hardware configuration
# - Working hardware accelerated video in Kodi as verified with 'intel_gpu_top'
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

  # NFS Shares
  # ------------------------------------------------------------------------------------------------
  services.rpcbind.enable = true; # needed for NFS
  fileSystems = {
    "/mnt/Movies" = {
      device = "192.168.1.2:/srv/nfs/Movies";
      fsType = "nfs";
      options = [ "auto" "noacl" "noatime" "nodiratime" "rsize=8192" "wsize=8192" "timeo=15" "_netdev" ];
    };
    "/mnt/Kids" = {
      device = "192.168.1.2:/srv/nfs/Kids";
      fsType = "nfs";
      options = [ "auto" "noacl" "noatime" "nodiratime" "rsize=8192" "wsize=8192" "timeo=15" "_netdev" ];
    };
    "/mnt/TV" = {
      device = "192.168.1.2:/srv/nfs/TV";
      fsType = "nfs";
      options = [ "auto" "noacl" "noatime" "nodiratime" "rsize=8192" "wsize=8192" "timeo=15" "_netdev" ];
    };
    "/mnt/Exercise" = {
      device = "192.168.1.2:/srv/nfs/Exercise";
      fsType = "nfs";
      options = [ "auto" "noacl" "noatime" "nodiratime" "rsize=8192" "wsize=8192" "timeo=15" "_netdev" ];
    };
    "/mnt/Pictures" = {
      device = "192.168.1.2:/srv/nfs/Pictures";
      fsType = "nfs";
      options = [ "auto" "noacl" "noatime" "nodiratime" "rsize=8192" "wsize=8192" "timeo=15" "_netdev" ];
    };
  };
}
