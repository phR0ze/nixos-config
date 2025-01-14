# Import all the options
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./boot.nix
    ./firmware.nix
    ./graphics-amd.nix
    ./graphics-intel.nix
    ./graphics-nvidia.nix
  ];
}
