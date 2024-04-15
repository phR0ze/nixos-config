# Backgrounds package
#
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:

pkgs.runCommandLocal "backgrounds" {} ''
  mkdir -p $out/share/backgrounds
  cp ${../../../include/usr/share/backgrounds}/* $out/share/backgrounds
''
