# XFCE minimal desktop configuration
#
# ### Features
# - Directly installable: minimal general purpose desktop environment
# --------------------------------------------------------------------------------------------------
{ config, pkgs, ... }:
{
  imports = [
    ../x11.nix
  ];

  # Enable XFCE
  system.xfce.enable = true;

  environment.systemPackages = with pkgs; [
    # Additional packages
  ];
}
