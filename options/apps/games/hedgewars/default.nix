# Hedgewars
#
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.games.hedgewars;
in
{
  options = {
    apps.games.hedgewars = {
      enable = lib.mkEnableOption "Install hedgewars";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ hedgewars ];
  };
}
