# Import all the options
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./incus.nix
    ./podman.nix
    ./virt-manager.nix
    ./winetricks.nix
  ];
}
