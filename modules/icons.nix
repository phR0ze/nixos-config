# Icons configuration
#
# NixOS uses /run/current-system/sw/share in place of /usr/share. By building packages that 
#---------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
let

  # Create an icons package out of our local custom icons
  # https://discourse.nixos.org/t/proper-way-to-access-share-folder/20495
  iconPackage = pkgs.stdenvNoCC.mkDerivation {
    name = "custom-hicolor-icons";
    src = ../../include/usr/share/icons/hicolor;
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
  # Add it to the /run/current-system/sw/ directory making it available
  environment.systemPackages = [
    iconsPackage
  ];
}
