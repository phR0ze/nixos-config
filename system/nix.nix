# Nix configuration
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  nix = {
    package = pkgs.nixFlakes
    settings.experimental-features = [ "nix-command" "flakes" ]; # enable flake support
  };
}

# vim:set ts=2:sw=2:sts=2
