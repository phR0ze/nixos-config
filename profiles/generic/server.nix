# XFCE server configuration
#
# ### Features
# - Directly installable: generic/desktop with additional server tools and configuration
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./desktop.nix
  ];

  development.rust.enable = true;
  virtualisation.boxes.enable = true;
  services.minecraft-server.enable = true;

  services.xserver.desktopManager.xfce.menu.overrides = [
    { source = "${pkgs.vscode}/share/applications/code.desktop"; categories = "Development"; }
  ];

  environment.systemPackages = with pkgs; [
    chromium                            # An open source web browser from Google
  ];
}
