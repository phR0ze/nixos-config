# Xnview options
# - no longer using this as Thunar does a better job
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.media.xnviewmp;

in
{
  options = {
    apps.media.xnviewmp = {
      enable = lib.mkEnableOption "Install and configure xnviewmp";
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ xnviewmp ];
    files.all.".config/xnviewmp/xnview.ini".weakCopy = ../../../../include/home/.config/xnviewmp/xnview.ini;
  };
}
