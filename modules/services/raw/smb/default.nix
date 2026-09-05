# SMB configuration
#
# - Samba is the Linux SMB implementation which used to be called cifs
# - Use the following to debug /etc/fstab syntax: mount -fav
# - Use the following to debug /etc/fstab syntax: findmnt --verify --verbose
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  host = config.host;
  hasSecrets = host.smb.secrets != null;

  shareName = x: builtins.baseNameOf x.mountPoint;

  # Legacy plaintext credential files (baked into the Nix store via environment.etc) — used only
  # as a fallback until this host has a `host.smb.secrets` file holding a `smb/<share>/pass`
  # key per entry.
  smbSecrets = builtins.listToAttrs (map (x: {
    name = "smb/secrets/${shareName x}";
    value.text = ''
      username=${x.user}
      password=${x.pass}
      domain=${x.domain}
    '';
  }) host.smb.entries);
in
{
  config = lib.mkIf (host.smb.enable) {
    environment.etc = lib.mkIf (!hasSecrets) smbSecrets;

    # Decrypted to /etc/smb/secrets/<share> at activation, never touching the Nix store
    files.templates = lib.mkIf hasSecrets (builtins.listToAttrs (map (x: {
      name = "smb-secrets-${shareName x}";
      value = {
        path = "/etc/smb/secrets/${shareName x}";
        filemode = "0400";
        content = ''
          username=${x.user}
          password=${config.sops.placeholder."smb/${shareName x}/pass"}
          domain=${x.domain}
        '';
        secrets."smb/${shareName x}/pass".sopsFile = host.smb.secrets;
      };
    }) host.smb.entries));

    fileSystems = (builtins.foldl' (a: x: {
      "${x.mountPoint}" = {
        device = x.remotePath;
        fsType = "cifs"; 
        options = x.options ++ [
          # Credentials location
          "credentials=/etc/smb/secrets/${builtins.baseNameOf x.mountPoint}"

          # Set smb 3 version and charset to convert local path names to and from unicode
          "vers=3.0,iocharset=utf8"

          # Use specific uid and gid for file ownership
          "uid=${toString config.users.users.${host.user.name}.uid},gid=${toString config.users.groups.${host.user.group}.gid}"

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
    } // a) {} host.smb.entries);

    # Install Samba utilities
    environment.systemPackages = with pkgs; [ cifs-utils ];
  };
}
