# Options for services that are installed directly on either a physical machine or a virtual machine
# as opposed to a container of some kind.
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./adguardhome
    ./caddy
    ./immich
    ./kasmvnc
    ./keyd
    ./minecraft
    ./mullvad
    ./private-internet-access
    ./selkies
    ./smartd
    ./sunshine
    ./synology-drive-client
    ./tailscale
    ./vaultwarden
    ./x11vnc
    ./x2go
  ];
}
