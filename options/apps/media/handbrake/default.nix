# HandBrake video transcoder
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.apps.media.handbrake;
in
{
  options = {
    apps.media.handbrake = {
      enable = lib.mkEnableOption "Install HandBrake video transcoder";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.handbrake ];
  };
}
