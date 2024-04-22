# XFCE theater configuration
#
# ### Features
# - Directly installable: xfce/desktop with additional media apps and configuration
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
let
  backgrounds = pkgs.callPackage ../../modules/desktop/backgrounds { };

in
{
  imports = [
    ./desktop.nix
  ];

  services.xserver.xft.theater = true;

  # High dpi settings
  services.xserver.xft.dpi = 130;
  services.xserver.desktopManager.xfce.panel.taskbar.size = 36;
  services.xserver.desktopManager.xfce.panel.taskbar.iconSize = 32;
  services.xserver.desktopManager.xfce.panel.launcher.size = 52;

  # Display configuration
  services.xserver.desktopManager.xfce.displays.connectingDisplay = 0;
  services.xserver.desktopManager.xfce.displays.resolution = { x = 1920; y = 1080; };

  # Configure theater system background
  services.xserver.desktopManager.xfce.desktop.background = lib.mkOverride 500
    "/run/current-system/sw/share/backgrounds/theater_curtains1.jpg";

  # Set the default background image to avoid initial boot changes
  services.xserver.displayManager.lightdm.background = lib.mkOverride 500
    "${backgrounds}/share/backgrounds/theater_curtains1.jpg";

  # Add additional theater package
  environment.systemPackages = with pkgs; [ ];

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
