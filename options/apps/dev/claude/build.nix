# Used for building directly for local tests
# 
# ### Build locally
# cd ~/Projects/nix-config/options/development/claude-code
# nix build -f ./build.nix
#---------------------------------------------------------------------------------------------------
let
  pkgs = import <nixpkgs> {
    config = {
      allowUnfree = true;
    };
  };
in pkgs.callPackage ./package.nix {}
