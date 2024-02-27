# Xserver configuration
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    desktopManager = {
      xfce.enable = true;
      xterm.enable = false;
    };
    displayManager.defaultSession = "xfce";
  };
}

# vim:set ts=2:sw=2:sts=2
