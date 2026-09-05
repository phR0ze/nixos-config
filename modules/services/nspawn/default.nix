# Container based services that normally have their own IP address and web portal e.g. Adguard Home.
#
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./portainer.nix
    ./stirling-pdf.nix
  ];
}
