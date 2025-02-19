# SMB configuration
#
# - Samba is the Linux SMB implementation which used to be called cifs
# - Use the following to debug /etc/fstab syntax: mount -fav
# - Use the following to debug /etc/fstab syntax: findmnt --verify --verbose
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;
in
{
  config = lib.mkIf (machine.smb.enable) {

    # Generate credential files for each mount as directed in /etc/smb/secrets/$SHARE
    environment.etc = (builtins.foldl' (a: x: {
      "smb/secrets/${builtins.baseNameOf x.mountPoint}".text = ''
          username=${x.user}
          password=${x.pass}
          domain=${x.domain}
        '';
      } // a) {} machine.smb.entries);

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
          "uid=${toString config.users.users.${machine.user.name}.uid},gid=${toString config.users.groups.users.gid}"

          # Ignore the server ids and always use client uid,gid for file ownership
          "forceuid,forcegid"

          # Specify default file, dir modes
          "dir_mode=0755,file_mode=0644"

          # Ensures systemd understands that the mount is network dependent
          "_netdev"

          # Mount the drive on first access
          "x-systemd.automount,noauto,x-systemd.mount-timeout=5s"

          # Automatically unmount after idle for this time
          "x-systemd.idle-timeout=1min"

          # Fail connecting to external mount after this time rather than default 90s
          "x-systemd.device-timeout=5s"

          # Specify the mount type, read-only (ro), read-write (rw)
          (if x.writable then "rw" else "ro")
        ];
      };
    } // a) {} machine.smb.entries);

    # Install Samba utilities
    environment.systemPackages = with pkgs; [ cifs-utils ];
  };
}
