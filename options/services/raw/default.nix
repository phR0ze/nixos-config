# Options for services that are installed directly on either a physical machine or a virtual machine 
# as opposed to a container of some kind.
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./adguardhome.nix
    ./barrier.nix
    ./immich.nix
    ./jellyfin.nix
    ./kasmvnc.nix
    ./minecraft.nix
    ./nfs.nix
    ./nix-cache.nix
    ./private-internet-access.nix
    ./rustdesk.nix
    ./smb.nix
    ./sshd.nix
    ./synology-drive-client.nix
    ./x11vnc.nix
  ];
}
