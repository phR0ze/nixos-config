# Default desktop configuration
#
# NixOS uses /run/current-system/sw/share in place of /usr/share
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:

let
  backgroundsPackage = pkgs.stdenvNoCC.mkDerivation {
    name = "backgrounds";
    src = ../../include/usr/share/backgrounds;
    installPhase = ''
      mkdir -p $out/share/backgrounds
      cp $src/* $out/share/backgrounds
    '';
  };
in
{
  # Add it to the /run/current-system/sw/ directory, making it available to the system
  environment.systemPackages = [
    backgroundsPackage
  ];
}
