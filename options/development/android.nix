# Android options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.development.android;
  machine = config.machine;
in
{
  options = {
    development.android = {
      enable = lib.mkEnableOption "Install and configure android tooling";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    programs.adb.enable = true;
    users.users.${machine.user.name}.extraGroups = [ "adbusers" ];
  };
}
