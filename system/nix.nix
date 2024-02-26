# Nix configuration
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  nix = {
    package = pkgs.nixFlakes;
    settings = {
      warn-dirty = false;
      trusted-users = ["root" "@wheel"];
      experimental-features = [ "nix-command" "flakes" ]; # enable flake support
    };

    gc = {
      automatic = true;
      dates = "weekly";
      # Delete older generations too
      options = "--delete-older-than 2d";
    };

    extraOptions = "experimental-features = nix-command flakes";
  };
}

# vim:set ts=2:sw=2:sts=2
