# Default modules configuration
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./locale.nix
    ./nix.nix
    ./sudo.nix
    ./users.nix
  ];
}

# vim:set ts=2:sw=2:sts=2
