# Homelab configuration
#
# ### Features
# - ?
# --------------------------------------------------------------------------------------------------
{ pkgs, lib, args, f, ... }:
{
  imports = [
    ../../profiles/server.nix
    ./hardware-configuration.nix
  ];
}
