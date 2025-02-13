# freecad options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.media.freecad;
in
{
  options = {
    apps.media.freecad = {
      enable = lib.mkEnableOption "Install and configure freecad";
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ freecad ];

    # Set the correct menu category to keep the menu clean
    services.xdg.menu.itemOverrides = [
      {
        categories = "Graphics";
        source = "${pkgs.freecad}/share/applications/org.freecad.FreeCAD.desktop";
      }
    ];
  };
}
