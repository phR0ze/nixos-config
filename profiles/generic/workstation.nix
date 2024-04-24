# XFCE workstation configuration
#
# ### Features
# - Directly installable: generic/develop with additional tools and configuration
# - barrier server configuration
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./desktop.nix
    ../../modules/desktop/x11/develop.nix
    ../../modules/services/barrier.nix
  ];

  # Additional programs and services
  services.barriers.enable = true;      # Enable the barrier server and client

  services.xserver.desktopManager.xfce.menu.overrides = [
    { source = "${pkgs.vscode}/share/applications/code.desktop"; categories = "Development"; }
  ];
}
