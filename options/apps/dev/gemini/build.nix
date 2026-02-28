# Used for building directly for local tests
#
# ### Build locally
# cd ~/Projects/nixos-config/options/apps/dev/gemini
# nix build -f ./build.nix
#---------------------------------------------------------------------------------------------------
let
  pkgs = import <nixpkgs> {
    config = {
      allowUnfree = true;
    };
  };
in pkgs.callPackage ./package.nix {}
