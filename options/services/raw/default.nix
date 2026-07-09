# Options for services that are installed directly on either a physical machine or a virtual machine
# as opposed to a container of some kind.
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./adguardhome
    ./immich
    ./jellyfin
    ./kasmvnc
    ./keyd
    ./minecraft
    ./mullvad
    ./nfs
    ./nix-cache
    ./private-internet-access
    ./selkies
    ./smb
    ./sshd
    ./sunshine
    ./synology-drive-client
    ./x11vnc
    ./x2go
  ];
}
