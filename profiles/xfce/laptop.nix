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

  services.raw.rustdesk.autostart = false;

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
