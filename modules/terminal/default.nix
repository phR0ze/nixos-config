# Default terminal configuration
#
# ### Features
# - bash
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./bash.nix
#    ./dircolors.nix
    ./starship.nix
  ];
}

# vim:set ts=2:sw=2:sts=2
