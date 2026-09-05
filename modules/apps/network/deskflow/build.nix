# Used for building directly for local tests
#
# ### Build locally
# cd ~/Projects/nixos-config/modules/apps/network/deskflow
# nix build -f ./build.nix
#---------------------------------------------------------------------------------------------------
let
  pkgs = import <nixpkgs> {};
in pkgs.deskflow
