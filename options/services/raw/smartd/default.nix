# Smartd configuration
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  cfg = config.services.raw.smartd;
in
{
  options = {
    services.raw.smartd = {
      enable = lib.mkEnableOption "Install and configure smartd disk health monitoring";
    };
  };

  config = lib.mkIf (cfg.enable) {
    services.smartd.enable = true;
  };
}
