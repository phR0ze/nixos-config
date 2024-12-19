# Import all the options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }:
{
  imports = [
    ./incus.nix
    ./podman.nix
    ./qemu-vms.nix
    ./virt-manager.nix
    ./winetricks.nix
  ];
}
