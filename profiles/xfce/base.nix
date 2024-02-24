# XFCE base configuration
#
# ### Features
# - Size: 
#---------------------------------------------------------------------------------------------------
{ config, lib, args, ... }:
{
  imports = [
    ../base/bootable.nix
  ];

  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };
    displayManager.defaultSession = "xfce";
  }; 
}

# vim:set ts=2:sw=2:sts=2
