# Used for building directly for local tests
# 
# ### Build locally
# cd ~/Projects/nixos-config/modules/apps/dev/opencode
# nix build -f ./build.nix
#---------------------------------------------------------------------------------------------------
let
  pkgs = import <nixpkgs> {
    config = {
      allowUnfree = true;
    };
  };
in pkgs.callPackage ./package.nix {}
