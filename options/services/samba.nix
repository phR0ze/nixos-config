# Samba configuration
#
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;
in
{
  config = lib.mkIf (machine.samba.enable) {

    fileSystems = (builtins.foldl' (a: x: {
      "${x.mountPoint}" = {
        device = x.remotePath;
        fsType = "cifs"; 
        options = [
          # Prevents hanging on network splits
          "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s"

          # Configure user credentials
          #"credentials=/etc/nixos/smb-secrets"

          # Use specific uid and gid for file ownership
          "uid=${toString config.users.users.${machine.user.name}.uid},gid=${toString config.users.groups.users.gid}"
        ];
      };
    } // a) {} machine.samba.entries);

    # Install Samba utilities
    environment.systemPackages = with pkgs; [ cifs-utils ];
  };
}
