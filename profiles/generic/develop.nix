# XFCE development configuration
#
# ### Features
# - Directly installable: generic/desktop with additional development tools and configuration
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./desktop.nix
    ../../modules/development/vscode
    ../../modules/desktop/x11/develop.nix
  ];

  development.rust.enable = true;

  services.xserver.desktopManager.xfce.menu.overrides = [
    { source = "${pkgs.vscode}/share/applications/code.desktop"; categories = "Development"; }
  ];

  environment.systemPackages = with pkgs; [
    chromium                            # An open source web browser from Google
  ];
}
