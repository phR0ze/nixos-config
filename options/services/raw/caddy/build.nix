# See README.md for update and build instructions.
#---------------------------------------------------------------------------------------------------
{ pkgs ? import <nixpkgs> { } }:
{
  caddy = pkgs.callPackage ./package.nix { };
}
