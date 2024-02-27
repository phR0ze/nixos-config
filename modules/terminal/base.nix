# Base terminal configuration
#
# ### Features
# - bash
# - dircolors
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./bash.nix
    ./dircolors.nix
  ];
}

# vim:set ts=2:sw=2:sts=2
