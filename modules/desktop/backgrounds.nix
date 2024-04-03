# Default desktop configuration
#
# NixOS uses /run/current-system/sw/share in place of /usr/share
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:

let
  backgroundsPackage = pkgs.stdenvNoCC.mkDerivation {
    name = "backgrounds";
    src = ../../include/usr/share/backgrounds;
    unpackPhase = ''
      cp $src
    '';
    buildPhase = "";
    installPhase = ''
      mkdir -p $out/share/icons/hicolor
      cp $src/* $out/share/icons/hicolor
    '';
  };
in
{
  # Add it to the /run/current-system/sw/ directory, making it available to the system
  environment.systemPackages = [
    backgroundsPackage
  ];
}
