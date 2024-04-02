# Default desktop configuration
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, ... }:
{
  # Adding background wallpaper for the desktop
  files.any."usr/share/backgrounds".link = ../../include/usr/share/backgrounds;
}
