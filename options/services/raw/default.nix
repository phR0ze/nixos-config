# Options for services that are installed directly on either a physical machine or a virtual machine 
# as opposed to a container of some kind.
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./barrier.nix
    ./jellyfin.nix
    ./minecraft.nix
    ./nfs.nix
    ./nix-cache.nix
    ./rustdesk.nix
    ./smb.nix
    ./sshd.nix
    ./x11vnc.nix
  ];
}
