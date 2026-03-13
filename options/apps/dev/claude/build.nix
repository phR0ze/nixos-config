# See README.md for update and build instructions.
#---------------------------------------------------------------------------------------------------
{ pkgs ? import <nixpkgs> { config.allowUnfree = true; } }:
{
  claude-code = pkgs.callPackage ./package.nix {};
}
