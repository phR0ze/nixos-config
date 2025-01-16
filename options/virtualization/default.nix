# Import all the options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }:
{
  imports = [
    ./incus.nix
    ./podman.nix
    ./microvm.nix
    ./virt-manager.nix
    ./winetricks.nix
  ];
}
