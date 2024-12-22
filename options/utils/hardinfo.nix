# hardinfo configuration
#
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.programs.hardinfo;

in
{
  options = {
    programs.hardinfo = {
      enable = lib.mkEnableOption "Install and configure hardinfo";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ hardinfo ];

    # Fix for hardinfo's xdg desktop file
    services.xdg.menu.itemOverrides = [
      {
        name = "HardInfo";
        icon = "${pkgs.hardinfo}/share/hardinfo/pixmaps/logo.png";
        source = "${pkgs.hardinfo}/share/applications/hardinfo.desktop";
      }
    ];
  };
}
