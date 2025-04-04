# Nix configuration

# Changes to nix settings get stored in /etc/nix/nix.conf
#
# ### Debug local binary cache 
# - nix-build '<nixpkgs>' -A pkgs.hello
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, inputs, ... }:
let
  machine = config.machine;
in
{
  config = lib.mkMerge [
    (lib.mkIf machine.nix.cache.enable {
      nix.settings = {
        # Add custom binary caches
        # - https://cache.nixos.org is added by default
        substituters = lib.mkBefore [ "http://${machine.nix.cache.ip}:${toString machine.nix.cache.port}" ];

        # Signing keys for custom substituters
        trusted-public-keys = [
          "${(builtins.readFile config.services.raw.nix-cache.host.publicKeyFile)}"
        ];
      };
    })
    {
      # Set the short git revision and comment to be used in the system version `clu list versions`
      system.configurationRevision = lib.mkIf (machine.git.comment != "") machine.git.comment;

      nix = {

        # Used in conjunction with registry.nixpkgs.flake below this sets up the NIX_PATH environment 
        # variable for older v2 binaries so they are using the correct nixpkgs and config versions.
        nixPath = [ "nixpkgs=${inputs.nixpkgs.outPath}" ];

        # Enable experimental features
        extraOptions = "experimental-features = nix-command flakes";

        # By configuring the nix registry to use our flake nixpkgs version we are pinning and aligning 
        # across the system which version fo nixpkgs to use. This will keep things clean and avoid 
        # downloading a new version constantly. Both using different versions and downloading the now 
        # 40Mb tarball are awful. This fixes that.
        registry.nixpkgs.flake = inputs.nixpkgs;

        # Nix settings
        # https://nixos.org/manual/nix/stable/command-ref/conf-file.html
        # ----------------------------------------------------------------------------------------------
        settings = {

          # Don't warn about dirty Git/Mercurial trees
          warn-dirty = false;

          # Users allowed to connect to the Nix daemon and thus make system changes
          trusted-users = ["root" "@wheel"];

          # Follow the XDG Base Directory Specification
          # https://nixos.org/manual/nix/stable/command-ref/nix-channel.html#xdg-base-directories
          use-xdg-base-directories = true;

          # Automatically detect files in the store that have identical contents and replaces them with
          # hard links to save disk space.
          auto-optimise-store = lib.mkDefault true;

          experimental-features = [
            "nix-command"    # 2.0 cli
            "flakes"         # flakes support
          ];
        };

        # Garbage collection settings
        # ----------------------------------------------------------------------------------------------
        gc = {
          #automatic = true;
          #dates = "weekly";

          # Delete older generations
          #options = "--delete-older-than 2d";
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
  ];
}
