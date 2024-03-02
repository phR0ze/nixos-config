# XFCE base configuration
#
# ### Features
# - Size: 8119.5 MiB
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  imports = [
    ../cli
  ];

  #hardware.pulseaudio.enable = true;
  services.xserver = {
    enable = true;
    desktopManager = {
      #xterm.enable = false;
      xfce.enable = true;
    };
    displayManager = {
      lightdm.enable = true;
      #defaultSession = "xfce";
    };
  };
  # plata-theme
  # arc-icon-theme

#  services.xserver = {
#    enable = true;
#    desktopManager = {
#      xfce.enable = true;
#      xfce.enableXfwm = true;
#      xterm.enable = false;
#    };
#    displayManager = {
#      defaultSession = "xfce";
#      #lightdm.enable = true;
#
#      # Conditionally autologin based on install settings
#      autoLogin = {
#        enable = args.settings.autologin;
#        user = args.settings.username;
#      };
#    };
#  }; 

#  programs.thunar.plugins = with pkgs.xfce; [
#    thunar-volman
#    thunar-archive-plugin
#  ];
  #environment.systemPackages = with pkgs; [
  #  gtk+-3.0
  #];
}

# vim:set ts=2:sw=2:sts=2
