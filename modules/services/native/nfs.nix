# NFS configuration
#
# ### Purpose
# - Mounts remote NFS exports as local filesystems via nfs-utils
# - Share definitions come from this host's build-time args (`host.services.native.nfs.*`, wired
#   into these options by `modules/default.nix`)
#
# ### Notes
# - Entries are translated directly into `fileSystems` i.e. /etc/fstab
# - Use the following to debug /etc/fstab syntax: mount -fav
# - Use the following to debug /etc/fstab syntax: findmnt --verify --verbose
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.services.native.nfs;
in
{
  options.services.native.nfs = {
    enable = lib.mkEnableOption "Mount the configured remote NFS shares";

    fsType = lib.mkOption {
      description = lib.mdDoc "Default filesystem type, when not overridden per entry";
      type = lib.types.str;
      default = "nfs";
      example = "nfs4";
    };

    options = lib.mkOption {
      description = lib.mdDoc "Default mount options, when not overridden per entry";
      type = lib.types.listOf lib.types.str;
      default = [ "auto" "noacl" "noatime" "nodiratime" "rsize=8192" "wsize=8192" "timeo=15" "_netdev" ];
    };

    entries = lib.mkOption {
      description = lib.mdDoc "Share entries to mount";
      default = [ ];
      type = lib.types.listOf (lib.types.submodule {
        options = {
          mountPoint = lib.mkOption {
            description = lib.mdDoc "Local mount point";
            type = lib.types.str;
            example = "/mnt/Media";
          };
          remotePath = lib.mkOption {
            description = lib.mdDoc "Remote path to use for the share";
            type = lib.types.str;
            example = "192.168.1.2:/srv/nfs/Media";
          };
          fsType = lib.mkOption {
            description = lib.mdDoc "Share filesystem type, defaults to `services.native.nfs.fsType`";
            type = lib.types.str;
            default = cfg.fsType;
          };
          options = lib.mkOption {
            description = lib.mdDoc "Share mount options, defaults to `services.native.nfs.options`";
            type = lib.types.listOf lib.types.str;
            default = cfg.options;
          };
        };
      });
    };
  };

  config = lib.mkIf cfg.enable {

    # NFS entries in /etc/fstab
    fileSystems = (builtins.foldl' (a: x: {
      "${x.mountPoint}" = {
        device = x.remotePath;
        fsType = x.fsType;
        options = x.options;
      };
    } // a) {} cfg.entries);

    services.rpcbind.enable = true;                         # NFS dependency
    environment.systemPackages = with pkgs; [ nfs-utils ];  # NFS utilities
  };
}
