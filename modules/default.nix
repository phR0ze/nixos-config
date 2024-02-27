# Base modules configuration
#
# ### Features
# - bash
# - dircolors
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./locale.nix
    ./nix.nix
    ./users.nix
    ./sudo.nix
  ];
}

# vim:set ts=2:sw=2:sts=2
