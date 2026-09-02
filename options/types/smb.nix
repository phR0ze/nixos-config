# Declares smb options type for reusability
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
{
  options = {
    enable = lib.mkOption {
      description = lib.mdDoc "Enable SMB shares";
      type = types.bool;
    };
    user = lib.mkOption {
      description = lib.mdDoc "Defalt access user if not overriden";
      type = types.str;
    };
    pass = lib.mkOption {
      description = lib.mdDoc "Defalt access pass if not overriden";
      type = types.str;
    };
    secrets = lib.mkOption {
      description = lib.mdDoc ''
        Path to the sops-encrypted file holding this machine's real `smb/<share>/pass` secrets
        (keyed by each entry's mountPoint basename). Independent of `machine.secrets` because SMB
        share passwords are inherently machine-specific and can't be satisfied by a shared/default
        secrets file. Leave unset to fall back to the legacy build-time-baked `pass` fields above.
      '';
      type = types.nullOr types.path;
      default = null;
      example = "./secrets.enc.yaml";
    };
    domain = lib.mkOption {
      description = lib.mdDoc "Default domain or workgroup to use";
      type = types.str;
      example = "WORKGROUP";
    };
    dirMode = lib.mkOption {
      description = lib.mdDoc "Default mode to use for directories";
      type = types.str;
      example = "0755";
    };
    fileMode = lib.mkOption {
      description = lib.mdDoc "Default mode to use for files";
      type = types.str;
      example = "0644";
    };
    entries = lib.mkOption {
      description = lib.mdDoc "Share entries to configure";
      type = types.listOf (types.submodule {
        options = {
          mountPoint = lib.mkOption {
            description = lib.mdDoc "Share mount point";
            type = types.str;
            example = "/mnt/Media";
          };
          remotePath = lib.mkOption {
            description = lib.mdDoc "Remote path to use for the share";
            type = types.str;
            example = "//<IP_OR_HOST>/path/to/share";
          };
          user = lib.mkOption {
            description = lib.mdDoc "Access user";
            type = types.str;
          };
          pass = lib.mkOption {
            description = lib.mdDoc "Access password";
            type = types.str;
          };
          domain = lib.mkOption {
            description = lib.mdDoc "Set the domain or workgroup to use";
            type = types.str;
            example = "WORKGROUP";
          };
          dirMode = lib.mkOption {
            description = lib.mdDoc "Mode to use for directories";
            type = types.str;
            example = "0755";
          };
          fileMode = lib.mkOption {
            description = lib.mdDoc "Mode to use for files";
            type = types.str;
            example = "0644";
          };
          writable = lib.mkOption {
            description = lib.mdDoc "Enable writing to the share";
            type = types.bool;
          };
          options = lib.mkOption {
            description = lib.mdDoc "Share options";
            type = types.listOf types.str;
            example = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=60" 
              "x-systemd.device-timeout=5s" "x-systemd.mount-timeout=5s" ];
          };
        };
      });
    };
  };
}
