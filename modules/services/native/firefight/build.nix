# Used for building directly for local tests, against the same nixpkgs-unstable this repo pins
#
# ### Build locally
# cd ~/Projects/nixos-config/modules/services/native/firefight
# nix build -f ./build.nix server
# nix build -f ./build.nix agent
# nix build -f ./build.nix app
#
# ### Build from a local firefight checkout instead of the pinned rev
# nix build -f ./build.nix --arg src ~/Projects/firefight app
#---------------------------------------------------------------------------------------------------
{ src ? null }:
let
  lock = (builtins.fromJSON (builtins.readFile ../../../../flake.lock)).nodes.nixpkgs-unstable.locked;
  pkgs = import (builtins.fetchTarball {
    url = "https://github.com/nixos/nixpkgs/archive/${lock.rev}.tar.gz";
    sha256 = lock.narHash;
  }) {};
  # A local checkout (including uncommitted work), minus build output and caches
  skip = [ ".git" "target" "build" ".dart_tool" ".gradle" "result" ];
  localSrc = if src == null then null else builtins.path {
    path = src;
    name = "firefight-src";
    filter = path: type: !(builtins.elem (baseNameOf path) skip);
  };
in
  pkgs.callPackage ./package.nix { src = localSrc; }
