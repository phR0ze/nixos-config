# Background configuration
#
# NixOS uses /run/current-system/sw/share in place of /usr/share
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
let
  # 1. Build the package from the local files
  backgroundsPackage = pkgs.runCommandLocal "backgrounds" {} ''
    mkdir -p $out/share/backgrounds
    cp ${../../include/usr/share/backgrounds}/* $out/share/backgrounds
  '';
in
{
  # 2. Add the package to the /nix/store
  environment.systemPackages = [
    backgroundsPackage
  ];

  # 3. Link the package to the system path /run/current-system/sw 
  # - searches all packages that have paths matching the list and merge links them
  environment.pathsToLink = [
    "/share/backgrounds"  # /run/current-system/sw/share/backgrounds
  ];
}
