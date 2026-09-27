# Options for services that are installed directly on either a physical machine or a virtual machine
# as opposed to a container of some kind.
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./immich
    ./kasmvnc
    ./sunshine
    ./x11vnc
    ./x2go
  ];
}
