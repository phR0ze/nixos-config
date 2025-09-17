# Options for services that are deployed as OCI containers.
#
# There are three primary reasons to deploy a service via containers on NixOS:
# - the ability to map web management interfaces to port 80 on a dedicated IP for the service there 
#   by allowing an intuitive experiance as well as separating out networking from the host server.
# - providing some additional security through a layer of isolation from the host server.
# - isolation from the NixOS version changes thus making the services more resilient to operating
#   system configuration issues.
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./homarr.nix
    ./lxconsole.nix
    ./oneup.nix
    ./portainer.nix
    ./qbittorrent.nix
    ./stirling-pdf.nix
    ./traefik.nix
  ];
}
