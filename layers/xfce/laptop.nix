# XFCE laptop configuration
#
# ### Features
# - Desktop with additional laptop tooling/configs
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  apps.network.rustdesk.autostart = false;

  # Slick captive portal solutions for hotels etc...
#  programs = {
#    captive-browser = {
#      enable = true;
#      interface = config.lib._custom_.wirelessInterface;
#    };
#  };

  # Add additional packages
  #environment.systemPackages = with pkgs; [
  #  
  #];
}
