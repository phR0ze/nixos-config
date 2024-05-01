# Android options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, ... }: with lib.types;
let
  cfg = config.development.android;
  
in
{
  options = {
    development.android = {
      enable = lib.mkEnableOption "Install and configure android tooling";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    programs.adb.enable = true;
    users.users.${args.settings.username}.extraGroups = [ "adbusers" ];
  };
}
