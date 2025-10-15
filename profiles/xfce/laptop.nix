# XFCE development configuration
#
# ### Features
# - Directly installable: desktop with additional laptop tooling/configs
# --------------------------------------------------------------------------------------------------
{ lib, ... }:
{
  imports = [
    ./desktop.nix
  ];

  # Slick captive portal solutions for hotels etc...
#  programs = {
#    captive-browser = {
#      enable = true;
#      interface = config.lib._custom_.wirelessInterface;
#    };
#  };

  # Add additional packages
  #environment.systemPackages = with pkgs; [
  #  zoom-us                   # Video conferencing application
  #];
}
