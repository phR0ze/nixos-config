# XFCE development configuration
#
# ### Features
# - Directly installable: desktop with additional laptop tooling/configs
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./desktop.nix
  ];

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
