# Homelab configuration
#
# ### Features
# - ?
# --------------------------------------------------------------------------------------------------
{ pkgs, lib, f, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../options
    ../../profiles/server.nix
  ];
};
