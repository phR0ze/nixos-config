# XFCE based workstation
#
# ### Features
# - Directly installable: xfce/develop with workstation specific configuration
# - barrier server configuration
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  imports = [
    ./xfce/develop.nix
  ];

  # Additional programs and services
  services.barriers.enable = true;      # Enable the barrier server and client
}
