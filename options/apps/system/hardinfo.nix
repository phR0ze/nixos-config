# hardinfo configuration
#
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.system.hardinfo;

in
{
  options = {
    apps.system.hardinfo = {
      enable = lib.mkEnableOption "Install and configure hardinfo";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ hardinfo2 ];

    # Fix for hardinfo's xdg desktop file
    system.xdg.menu.itemOverrides = [
      {
        name = "HardInfo";
        icon = "${pkgs.hardinfo2}/share/hardinfo2/pixmaps/hardinfo2.png";
        source = "${pkgs.hardinfo2}/share/applications/hardinfo2.desktop";
      }
    ];
  };
}
