# NFS configuration
#
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;

  # Convert the list of share entries into a set of fileSystems
  entries = builtins.foldl' (a: x: { "${x.mountPoint}" = { device = x.remotePath; fsType = x.fsType; 
      options = x.options; }; } // a) {} machine.nfs.entries;
in
{
  config = lib.mkIf (machine.nfs.enable) {
    fileSystems = entries;                                  # NFS entries in /etc/fstab
    services.rpcbind.enable = true;                         # NFS dependency
    environment.systemPackages = with pkgs; [ nfs-utils ];  # NFS utilities
  };
}
