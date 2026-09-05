# Used for building directly for local tests
#
# ### Build locally
# cd ~/Projects/nixos-config/options/devices/rtw88
# nix build -f ./build.nix
#---------------------------------------------------------------------------------------------------
let
  pkgs = import <nixpkgs> {};
in pkgs.linuxPackages.callPackage ./package.nix {}
