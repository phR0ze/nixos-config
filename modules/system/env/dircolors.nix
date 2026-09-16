# Dircolors configuration
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  cfg = config.system.env;
in
{
  options = {
    system.env = {
      dircolors.enable = lib.mkEnableOption "Enable custom dircolors for the terminal";
    };
  };

  config = lib.mkIf (cfg.dircolors.enable) {
    files.all.".dircolors".copy = ./include/dircolors;
  };
}
