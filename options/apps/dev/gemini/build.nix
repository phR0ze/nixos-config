# See README.md for update and build instructions.
#---------------------------------------------------------------------------------------------------
{ pkgs ? import <nixpkgs> { config.allowUnfree = true; } }:

{
  gemini-cli = pkgs.callPackage ./package.nix {};
}
