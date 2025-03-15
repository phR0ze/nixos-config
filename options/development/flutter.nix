# Flutter options
#
# ### Getting started
# -
#
# ### References
# - 
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.development.flutter;
in
{
  options = {
    development.flutter = {
      enable = lib.mkEnableOption "Configure flutter dev environment";
    };
  };
 
  config = lib.mkIf (cfg.enable) {

    # Enable Android development
    development.android.enable = true;

    # Install flutter and dependencies
    environment.systemPackages = [
      pkgs.flutter
    ];
  };
}
