# Homelab configuration
#
# ### Features
# - ?
# --------------------------------------------------------------------------------------------------
{ pkgs, lib, f, ... }:
{
  imports = [
    ../../options
    ../../profiles/server.nix
    ./hardware-configuration.nix
  ];
};
