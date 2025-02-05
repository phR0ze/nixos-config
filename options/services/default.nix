# Import all the options
#
# Splitting out standalone services that you might run in your homelab that would normally have their 
# own IP address and web portal e.g. Adguard Home.
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./barrier.nix
    ./cache.nix
    ./cont.nix
    ./nfs.nix
    ./smb.nix
    ./sshd.nix
    ./x11vnc.nix
  ];
}
