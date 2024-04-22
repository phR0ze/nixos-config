# XFCE development configuration
#
# ### Features
# - Directly installable: generic/desktop with additional development tools and configuration
# - barrier server configuration
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./desktop.nix
    ../../modules/desktop/x11/develop.nix
  ];

  services.xserver.desktopManager.xfce.menu.overrides = [
    { source = "${pkgs.vscode}/share/applications/code.desktop"; categories = "Development"; }
  ];
}
