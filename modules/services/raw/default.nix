# Options for services that are installed directly on either a physical machine or a virtual machine
# as opposed to a container of some kind.
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./immich
    ./kasmvnc
    ./minecraft
    ./mullvad
    ./private-internet-access
    ./selkies
    ./smartd
    ./sunshine
    ./tailscale
    ./x11vnc
    ./x2go
  ];
}
