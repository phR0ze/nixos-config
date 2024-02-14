# Nix configuration
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  nix = {
    package = pkgs.nixFlakes;
    settings.experimental-features = [ "nix-command" "flakes" ]; # enable flake support
    extraOptions = "experimental-features = nix-command flakes";
  };
}

# vim:set ts=2:sw=2:sts=2
