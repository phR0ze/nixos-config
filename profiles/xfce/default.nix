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
      xfce.enable = true;
      xterm.enable = false;
    };
    displayManager = {
      lightdm.enable = true;
      defaultSession = "xfce";

      # Conditionally autologin based on install settings
      autoLogin = {
        enable = args.settings.autologin;
        user = args.settings.username;
      };
    };
  }; 

  programs.thunar.plugins = with pkgs.xfce; [
    thunar-volman
    thunar-archive-plugin
  ];
}

# vim:set ts=2:sw=2:sts=2
