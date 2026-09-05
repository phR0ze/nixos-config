# See README.md for patch update and build instructions.
#---------------------------------------------------------------------------------------------------
{ pkgs ? import <nixpkgs> { config.allowUnfree = true; } }:
{
  prismlauncher = pkgs.callPackage ./package.nix {};
}
