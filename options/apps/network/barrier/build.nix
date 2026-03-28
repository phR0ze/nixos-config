# Build barrier locally with: nix build -f build.nix
#---------------------------------------------------------------------------------------------------
{ pkgs ? import <nixpkgs> {} }:
{
  barrier = pkgs.callPackage ./package.nix {};
}
