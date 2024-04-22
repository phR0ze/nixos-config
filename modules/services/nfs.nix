# NFS configuration
#
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.services.nfs.client.shares;

in
{
  options = {
    services.nfs.client.shares = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Whether to enable NFS client shares on this system.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nfs-utils                           # Linux user-space NFS utilities
    ];

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
  };
}
