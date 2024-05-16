# dmenu configuration
#
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, ... }: with lib.types;
let
  cfg = config.programs.dmenu;

in
{
  options = {
    programs.dmenu = {
      enable = lib.mkEnableOption "Install and configure dmenu";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ dmenu ];
  };
}
