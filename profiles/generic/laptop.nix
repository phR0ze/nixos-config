# XFCE development configuration
#
# ### Features
# - Directly installable: generic/desktop with additional tooling and configuration for laptops
# --------------------------------------------------------------------------------------------------
{ lib, ... }:
{
  imports = [
    ./desktop.nix
    ../../modules/desktop/x11/develop.nix
  ];

  # Disable x11vnc for laptops
  services.x11vnc.enable = lib.mkForce false;

  # Add additional packages
  # Slick captive portal solutions for hotels etc...
#  programs = {
#    captive-browser = {
#      enable = true;
#      interface = config.lib._custom_.wirelessInterface;
#    };
#  };
}
