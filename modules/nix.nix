# Nix configuration
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, ... }:
{
  nix = {
    package = pkgs.nixFlakes;

    # Sets up the NIX_PATH environment variable to use the flake nixpkgs for commands like nix-shell
    nixPath = [
      "nixpkgs=${args.nixpkgs.outPath}"
#      "nixos-config=path:/etc/nixos#install"
    ];

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

  # Write the current set of packages out to /etc/packages
  environment.etc."packages".text =
  let
    packages = builtins.map (p: p.name) config.environment.systemPackages;
    sortedUnique = builtins.sort builtins.lessThan (lib.unique packages);
    formatted = builtins.concatStringsSep "\n" sortedUnique;
  in
    formatted;
}

# vim:set ts=2:sw=2:sts=2
