# Used for building directly for local tests
# 
# ### Build locally
# cd ~/Projects/nix-config/options/apps/system/clu
# nix build -f ./build.nix
#---------------------------------------------------------------------------------------------------
let
  # Packages only works here because I'm running the same nixpkgs unstable SHA as this system is 
  # getting built with as well otherwise there would be a mismatch.
  pkgs = import <nixpkgs> {};
in
  pkgs.callPackage ./package.nix {}
