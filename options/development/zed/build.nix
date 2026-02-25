# Used for building directly for local tests
# 
# ### Build locally
# nix build -f ./build.nix
#---------------------------------------------------------------------------------------------------
let
  pkgs = import <nixpkgs> {};
in pkgs.callPackage ./package.nix {}
