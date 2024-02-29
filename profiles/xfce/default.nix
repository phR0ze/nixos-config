# XFCE base configuration
#
# ### Features
# - Size: 8119.5 MiB
#---------------------------------------------------------------------------------------------------
{ config, lib, args, ... }:
{
  imports = [
    ../cli
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
