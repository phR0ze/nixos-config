# Roblox
#
# Manual steps
# 1. flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
# 2. flatpak install flathub org.vinegarhq.Sober
# 3. flatpak run org.vinegarhq.Sober
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  xfce = config.system.xfce;
  cfg = config.apps.games.roblox;
in
{
  options = {
    apps.games.roblox = {
      enable = lib.mkEnableOption "Install and config roblox";
    };
  };

  config = lib.mkMerge [

    # Install roblox
    (lib.mkIf (cfg.enable) {
      services.flatpak.enable = true;
    })

    # XFCE supporting configuration
    (lib.mkIf (xfce.enable) {
      xdg.portal.enable = true;
      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

      # TODO: add desktop icon in menu
      #files.all.".config/xfce4/xfconf/xfce-perchannel-xml/displays.xml".copy = xmlfile;
      #system.xdg.menu.itemOverrides = [
      #  { source = "${pkgs.vscode}/share/applications/code.desktop"; categories = "Development"; }
      #];
    })
  ];
}
