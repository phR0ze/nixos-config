# SMB configuration
#
# ### Purpose
# - Mounts remote SMB/CIFS shares as local filesystems via cifs-utils
# - Share definitions come from this host's build-time args (`host.services.native.smb.*`, wired
#   into these options by `modules/default.nix`), passwords from its runtime secrets
#
# ### Notes
# - Samba is the Linux SMB implementation which used to be called cifs
# - Use the following to debug /etc/fstab syntax: mount -fav
# - Use the following to debug /etc/fstab syntax: findmnt --verify --verbose
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, utils, ... }:
let
  cfg = config.services.native.smb;

  shareName = x: baseNameOf x.mountPoint;
in
{
  options.services.native.smb = {
    enable = lib.mkEnableOption "Mount the configured remote SMB/CIFS shares";

    sopsFile = lib.mkOption {
      description = lib.mdDoc ''
        Path to the sops-encrypted file holding this host's real share passwords, decrypted at
        activation time by sops-nix. Each entry's `secretRef` names a flat top-level key in this
        file whose value is that share's password directly. Defaults to `host.sopsFile`.
      '';
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "./secrets.enc.yaml";
    };

    uid = lib.mkOption {
      description = lib.mdDoc ''
        Numeric owner applied to every file on every share (`forceuid`). Numeric rather than a
        user name because the primary user's name is itself a runtime secret now
        (`system.users.admin`), so it can't be resolved at evaluation time - 1000 is the uid that
        module pins for the admin account.
      '';
      type = lib.types.int;
      default = 1000;
    };

    gid = lib.mkOption {
      description = lib.mdDoc ''
        Numeric group applied to every file on every share (`forcegid`). Same reasoning as `uid`;
        100 is the shared `users` group created by `system.users.desktopExtras`.
      '';
      type = lib.types.int;
      default = 100;
    };

    user = lib.mkOption {
      description = lib.mdDoc "Default access user, when not overridden per entry";
      type = lib.types.str;
      default = "";
    };

    domain = lib.mkOption {
      description = lib.mdDoc "Default domain or workgroup, when not overridden per entry";
      type = lib.types.str;
      default = "";
      example = "WORKGROUP";
    };

    dirMode = lib.mkOption {
      description = lib.mdDoc "Default mode for directories, when not overridden per entry";
      type = lib.types.str;
      default = "0755";
    };

    fileMode = lib.mkOption {
      description = lib.mdDoc "Default mode for files, when not overridden per entry";
      type = lib.types.str;
      default = "0644";
    };

    entries = lib.mkOption {
      description = lib.mdDoc "Share entries to mount";
      default = [ ];
      type = lib.types.listOf (lib.types.submodule {
        options = {
          mountPoint = lib.mkOption {
            description = lib.mdDoc "Local mount point, its basename names the share's secret and credentials file";
            type = lib.types.str;
            example = "/mnt/Media";
          };
          remotePath = lib.mkOption {
            description = lib.mdDoc "Remote path to use for the share";
            type = lib.types.str;
            example = "//<IP_OR_HOST>/path/to/share";
          };
          secretRef = lib.mkOption {
            description = lib.mdDoc ''
              Full sops secret key (in `sopsFile`) whose *value* is this share's password
              directly - a flat, opaque key independent of `mountPoint`/`remotePath` so the real
              share name never appears as a plaintext key in the encrypted secrets file. Pick any
              non-descriptive value (e.g. a short id); it must be unique among this host's entries
              and match the corresponding top-level key in `secrets.enc.yaml`.
            '';
            type = lib.types.str;
            example = "smb/secretA";
          };
          user = lib.mkOption {
            description = lib.mdDoc "Access user, defaults to `services.native.smb.user`";
            type = lib.types.str;
            default = cfg.user;
          };
          domain = lib.mkOption {
            description = lib.mdDoc "Domain or workgroup, defaults to `services.native.smb.domain`";
            type = lib.types.str;
            default = cfg.domain;
          };
          dirMode = lib.mkOption {
            description = lib.mdDoc "Mode for directories, defaults to `services.native.smb.dirMode`";
            type = lib.types.str;
            default = cfg.dirMode;
          };
          fileMode = lib.mkOption {
            description = lib.mdDoc "Mode for files, defaults to `services.native.smb.fileMode`";
            type = lib.types.str;
            default = cfg.fileMode;
          };
          writable = lib.mkOption {
            description = lib.mdDoc "Enable writing to the share";
            type = lib.types.bool;
            default = false;
          };
          options = lib.mkOption {
            description = lib.mdDoc "Additional mount options, merged with the defaults below";
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [ "x-systemd.idle-timeout=60" ];
          };
        };
      });
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.sopsFile != null;
        message = "services.native.smb is enabled but services.native.smb.sopsFile is not set.";
      }
    ];

    # Install Samba utilities
    environment.systemPackages = with pkgs; [
      cifs-utils 
    ];

    # Decrypted to /etc/smb/secrets/<share> at activation, never touching the Nix store
    secret.templates = builtins.listToAttrs (map (x: {
      name = "smb-secrets-${shareName x}";
      value = {
        path = "/etc/smb/secrets/${shareName x}";
        filemode = "0400";
        content = ''
          username=${x.user}
          password=${config.secret.ref."${x.secretRef}"}
          domain=${x.domain}
        '';
        secrets."${x.secretRef}".sopsFile = cfg.sopsFile;

        # cifs reads the credentials file at mount time
        restartUnits = [ "${utils.escapeSystemdPath x.mountPoint}.mount" ];
      };
    }) cfg.entries);

    fileSystems = (builtins.foldl' (a: x: {
      "${x.mountPoint}" = {
        device = x.remotePath;
        fsType = "cifs";
        options = x.options ++ [
          # Credentials location
          "credentials=/etc/smb/secrets/${shareName x}"

          # Set smb 3 version and charset to convert local path names to and from unicode
          "vers=3.0,iocharset=utf8"

          # Use specific uid and gid for file ownership
          "uid=${toString cfg.uid},gid=${toString cfg.gid}"

          # Ignore the server ids and always use client uid,gid for file ownership
          "forceuid,forcegid"

          # Specify default file, dir modes
          "dir_mode=${x.dirMode},file_mode=${x.fileMode}"

          # Ensures systemd understands that the mount is network dependent
          "_netdev"

          # Mount the drive on first access. mount-timeout must be generous enough
          # for CIFS session setup to complete over WiFi (5s was too short).
          "x-systemd.automount,noauto,x-systemd.mount-timeout=60s"

          # Automatically unmount after idle for this time. 1min caused constant
          # remount churn when browsing with Thunar — all mounts would drop and
          # re-trigger simultaneously on the next directory access.
          "x-systemd.idle-timeout=10min"

          # Fail connecting to external mount after this time rather than default 90s
          "x-systemd.device-timeout=30s"

          # Specify the mount type, read-only (ro), read-write (rw)
          (if x.writable then "rw" else "ro")
        ];
      };
    } // a) {} cfg.entries);
  };
}
