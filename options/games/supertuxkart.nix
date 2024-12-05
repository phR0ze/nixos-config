# Super Tux Kart
#
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.programs.superTuxKart;

in
{
  options = {
    programs.superTuxKart = {
      enable = lib.mkEnableOption "Install super Tux Kart";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ superTuxKart ];
  };
}