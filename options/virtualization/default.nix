# Import all the options
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./podman.nix
    ./virt-manager.nix
    ./winetricks.nix
  ];
}
