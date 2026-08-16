# Options for services that are installed directly on either a physical machine or a virtual machine
# as opposed to a container of some kind.
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./adguardhome
    ./caddy
    ./immich
    ./jellyfin
    ./kasmvnc
    ./keyd
    ./minecraft
    ./mullvad
    ./nfs
    ./nix-cache
    ./podman
    ./private-internet-access
    ./selkies
    ./smb
    ./sshd
    ./sunshine
    ./synology-drive-client
    ./tailscale
    ./vaultwarden
    ./x11vnc
    ./x2go
  ];
}
