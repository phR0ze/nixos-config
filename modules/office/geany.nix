# Geany options
#
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.programs.geany;
in
{
  options = {
    programs.geany = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Install smplayer";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {
      environment.systemPackages = with pkgs; [ geany ];
      files.all.".config/geany/colorschemes".link = ../../include/home/.config/geany/colorschemes;
      files.all.".config/geany/plugins".link = ../../include/home/.config/geany/plugins;
      files.all.".config/geany/geany.conf".copy = ../../include/home/.config/geany/geany.conf;
    })
  ];
}
