# Default modules configuration
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
