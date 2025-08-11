# veracrypt configuration
# Free Open-Source filesystem encryption
#
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.system.veracrypt;

in
{
  options = {
    apps.system.veracrypt = {
      enable = lib.mkEnableOption "Install and configure hardinfo";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ veracrypt ];

    # Place veracrypt in the correct XFCE menu
    services.xdg.menu.itemOverrides = [
      {
        categories = "System";
        source = "${pkgs.veracrypt}/share/applications/veracrypt.desktop";
      }
    ];
  };
}
