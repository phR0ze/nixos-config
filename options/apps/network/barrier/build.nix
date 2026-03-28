# Build barrier locally with: nix build -f build.nix
#---------------------------------------------------------------------------------------------------
# Build barrier locally with: nix build -f build.nix barrier
#
# Explicit overrides bridge the gap between the system nixpkgs (which may still
# use the legacy xorg.* paths) and the new top-level aliases used in package.nix.
#---------------------------------------------------------------------------------------------------
{ pkgs ? import <nixpkgs> {} }:
{
  barrier = pkgs.callPackage ./package.nix {
    libx11 = pkgs.xorg.libX11;
    libxext = pkgs.xorg.libXext;
    libxtst = pkgs.xorg.libXtst;
  };
}
