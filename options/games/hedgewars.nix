# Hedgewars
#
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.programs.hedgewars;

in
{
  options = {
    programs.hedgewars = {
      enable = lib.mkEnableOption "Install hedgewars";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ hedgewars ];
  };
}
