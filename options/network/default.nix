# Import all the options
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./filezilla.nix
    ./firefox.nix
    ./qbittorrent.nix
    ./network-manager.nix
  ];
}
