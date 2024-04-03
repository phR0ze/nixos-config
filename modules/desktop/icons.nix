# Icons configuration
#
# NixOS uses /run/current-system/sw/share in place of /usr/share
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
let
  # 1. Build the package from the local files
  iconsPackage = pkgs.runCommandLocal "icons" {} ''
    mkdir -p $out/share/icons/hicolor
    cp -r ${../../include/usr/share/icons/hicolor}/* $out/share/icons/hicolor
  '';
in
{
  # 2. Add the package to the /nix/store
  environment.systemPackages = [
    iconsPackage
  ];

  # 3. Link the package to the system path /run/current-system/sw 
  # - searches all packages that have paths matching the list and merge links them
  environment.pathsToLink = [
    "/share/icons/hicolor"  # /run/current-system/sw/share/icons/hicolor
  ];
}
