# Minimal desktop independent X11 configuration
#
# ### Features
# - Directly installable
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, ... }:
{
  imports = [
    ../cli
    ../../modules/xdg.nix
    ../../modules/fonts.nix
    ../../modules/services/xserver.nix
    ../../modules/networking/network-manager.nix
  ];
}

# vim:set ts=2:sw=2:sts=2
