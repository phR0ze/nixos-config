# XFCE development configuration
#
# ### Features
# - Directly installable: desktop with additional tooling and configuration for laptops
# --------------------------------------------------------------------------------------------------
{ lib, ... }:
{
  imports = [
    ./desktop.nix
  ];

  # Add additional packages
  # Slick captive portal solutions for hotels etc...
#  programs = {
#    captive-browser = {
#      enable = true;
#      interface = config.lib._custom_.wirelessInterface;
#    };
#  };
}
