# Desktop assets package
#
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:

pkgs.runCommandLocal "desktop-assets" {} ''
  mkdir -p $out/share/backgrounds
  cp ${../../include/usr/share/backgrounds}/* $out/share/backgrounds

  mkdir -p $out/share/icons/hicolor
  cp -r ${../../include/usr/share/icons/hicolor}/* $out/share/icons/hicolor
''
