# Geany options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.office.geany;
in
{
  options = {
    apps.office.geany = {
      enable = lib.mkEnableOption "Install and configure geany";
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ geany ];

    files.all.".config/geany/colorschemes".link = ../../include/home/.config/geany/colorschemes;
    files.all.".config/geany/plugins".link = ../../include/home/.config/geany/plugins;
    files.all.".config/geany/geany.conf".weakCopy = ../../include/home/.config/geany/geany.conf;
  };
}
