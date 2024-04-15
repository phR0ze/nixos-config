# Backgrounds module
#
# NixOS uses /run/current-system/sw/share in place of /usr/share
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
let
  backgrounds = pkgs.callPackage ./default.nix { };

in
{

  # 2. Add the package to the /nix/store
  environment.systemPackages = [
    backgrounds
  ];

  # 3. Link the package to the system path /run/current-system/sw 
  # - searches all packages that have paths matching the list and merge links them
  environment.pathsToLink = [
    "/share/backgrounds"  # /run/current-system/sw/share/backgrounds
  ];
}
