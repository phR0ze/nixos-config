# Declares NFS share option type for reusability
#
# https://nixos.org/manual/nixos/stable/#ex-submodule-direct
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
{
  options = {

    mountPoint = lib.mkOption {
      description = lib.mdDoc "NFS Share mount point";
      type = types.nullOr types.str;
      default = null;
      example = "/mnt/Media";
    };

    remotePath = lib.mkOption {
      description = lib.mdDoc "Remote path to use for the NFS Share";
      type = types.nullOr types.str;
      default = null;
      example = "192.168.1.2:/srv/nfs/Media";
    };
  };
}
