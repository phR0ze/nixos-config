# Used for directly testing the package
# nix build -f ./direct.nix
#
# Build a specific variable from the package
# nix build -f ./direct.nix plugins
let
  pkgs = import <nixpkgs> {};
in
  pkgs.callPackage ./neovim.nix {}
