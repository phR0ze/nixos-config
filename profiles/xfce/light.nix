# XFCE minimal desktop configuration
#
# ### Features
# - Directly installable: minimal general purpose desktop environment
# --------------------------------------------------------------------------------------------------
{ config, pkgs, ... }:
let
  machine = config.machine;
in
{
  imports = [
    ../xorg.nix
  ];

  # Enable XFCE and all needed components
  services.xserver.desktopManager.xfce.enable = true;

  environment.systemPackages = with pkgs; [
    # Additional packages
  ];
}
