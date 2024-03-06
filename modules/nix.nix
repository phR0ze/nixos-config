# Nix configuration
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, ... }:
{
  nix = {
    package = pkgs.nixFlakes;

    # Sets up the NIX_PATH environment variable to use the flake nixpkgs for older nix2 commands
    # e.g. nix-shell
    nixPath = [ "nixpkgs=${args.nixpkgs.outPath}" ];

    # Nix settings
    # https://nixos.org/manual/nix/stable/command-ref/conf-file.html
    # ----------------------------------------------------------------------------------------------
    settings = {

      # Don't warn about dirty Git/Mercurial trees
      warn-dirty = false;

      # Users allowed to connect to the Nix daemon and thus make system changes
      trusted-users = ["root" "@wheel"];

      # Follow the XDG Base Directory Specification
      use-xdg-base-directories = true;

      # Automatically detect files in the store that have identical contents and replaces them with
      # hard links to save disk space.
      auto-optimise-store = lib.mkDefault true;

      # Add custom binary caches
      #substituters = lib.mkBefore [ "https.mirrors.somesite.com/nix-channels/store" ]
#      substituters = [
#        "https://nix-community.cachix.org/"
#        "https://cache.nixos.org/"
#      ];

      experimental-features = [
        "nix-command"    # 2.0 cli
        "flakes"         # flakes support
        "repl-flake"     # 2.0 cli support for 'nix repl'
      ];
    };
    extraOptions = "experimental-features = nix-command flakes";

    # Garbage collection settings
    # ----------------------------------------------------------------------------------------------
    gc = {
      automatic = true;
      dates = "weekly";

      # Delete older generations
      options = "--delete-older-than 2d";
    };
  };

  # Write the current set of packages out to /etc/packages
  # Only catches just the packages in the flake and not it's dependencies. Not a great solution
  # ------------------------------------------------------------------------------------------------
  environment.etc."packages".text =
  let
    packages = builtins.map (p: p.name) config.environment.systemPackages;
    sortedUnique = builtins.sort builtins.lessThan (lib.unique packages);
    formatted = builtins.concatStringsSep "\n" sortedUnique;
  in
    formatted;
}

# vim:set ts=2:sw=2:sts=2
