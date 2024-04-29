# Import all the options
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./filezilla.nix
    ./qbittorrent.nix
    ./network-manager.nix
  ];
}
