# Used for building directly for local tests
# 
# ### Build locally
# cd ~/Projects/nix-config/options/apps/system/neovim
# nix build -f ./build.nix
#
# ### Build a specific variable from the package
# nix build -f ./build.nix plugins
#---------------------------------------------------------------------------------------------------
let
  pkgs = import <nixpkgs> {};
in
  pkgs.callPackage ./neovim.nix {}
