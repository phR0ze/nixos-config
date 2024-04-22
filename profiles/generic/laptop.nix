# XFCE development configuration
#
# ### Features
# - Directly installable: generic/desktop with additional development tools and configuration
# - barrier server configuration
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./desktop.nix
    ../../modules/desktop/x11/develop.nix
  ];

  # Slick captive portal solutions for hotels etc...
#  programs = {
#    captive-browser = {
#      enable = true;
#      interface = config.lib._custom_.wirelessInterface;
#    };
#  };
}
