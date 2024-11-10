# Import all the options
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./amd-graphics.nix
    ./intel-graphics.nix
    ./nvidia-graphics.nix
  ];
}
