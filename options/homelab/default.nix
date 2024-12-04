# Import all the homelab options
#
# Homelab is being defined here to be anything that has it's own web management interface and thus 
# would make intuitively make use of port 80. Rather than map ports all over the place I've decided 
# to deploy these services as containers with their own IP addresses to allow for this intuitive 
# interaction on port 80 for their web management interfaces.
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./adguard.nix
    ./stirling-pdf.nix
  ];
}
