# Default desktop configuration
#
# NixOS uses /run/current-system/sw/share in place of /usr/share
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
let
  backgroundsPackage = pkgs.runCommandLocal "backgrounds" {} ''
    mkdir -p $out/share/backgrounds
    cp ${../../include/usr/share/backgrounds}/* $out/share/backgrounds
  '';
in
{
  # Search all packages that have paths matching the list and link them in
  # the system directory /run/current-system/sw
  environment.pathsToLink = [
    "/share/backgrounds"
  ];

  # Add the package to the /nix/store
  environment.systemPackages = [
    backgroundsPackage
  ];
}

#let
#  backgroundsPackage = pkgs.stdenvNoCC.mkDerivation {
#    name = "backgrounds";
#    src = ../../include/usr/share/backgrounds;
#    installPhase = ''
#      mkdir -p $out/share/backgrounds
#      cp $src/* $out/share/backgrounds
#    '';
#  };
#in
#{
#  # Add a link to /run/current-system/sw/ to make the package available
#  environment.pathsToLink = [
#    "/share/icons/hicolor"      # searches all packages that have this path and links them
#  ];
#
#  # Add the package to the /nix/store
#  environment.systemPackages = [
#    backgroundsPackage
#  ];
#}
