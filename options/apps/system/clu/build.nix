# Used for building directly for local tests
# 
# ### Build locally
# cd ~/Projects/nix-config/options/apps/system/clu
# nix build -f ./build.nix
#---------------------------------------------------------------------------------------------------
let
  pkgs = import <nixpkgs> {};
in
  pkgs.callPackage ./default.nix {}
