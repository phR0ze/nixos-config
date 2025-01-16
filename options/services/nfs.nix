# NFS configuration
#
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;

  # Convert the list of share entries into a set of fileSystems
  entries = builtins.foldl' (a: x: { "${x.mountPoint}" = { device = x.remotePath; fsType = x.fsType; 
      options = x.options; }; } // a) {} machine.shares.entries;
in
{
  config = lib.mkIf (machine.shares.enable) {
    fileSystems = entries;                                  # NFS entries in /etc/fstab
    services.rpcbind.enable = true;                         # NFS dependency
    environment.systemPackages = with pkgs; [ nfs-utils ];  # NFS utilities
  };
}
