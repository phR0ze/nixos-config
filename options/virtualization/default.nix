# Import all the options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }:
{
  imports = [
    ./incus.nix
    ./podman.nix
    ./qemu.nix
    ./virt-manager.nix
    ./winetricks.nix
  ];
}
