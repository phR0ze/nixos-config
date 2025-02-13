# qview options
# - Simple image viewer with webp support
#
# ### Configure
# - First run popup to not display
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.media.qview;

  confFile = lib.mkIf cfg.enable
    (pkgs.writeText "qView.conf" ''
      [General]
      firstlaunch=true

      [options]
      askdelete=false

      [shortcuts]
      quit=Esc
    '');
in
{
  options = {
    apps.media.qview = {
      enable = lib.mkEnableOption "Install and configure qview";
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ qview ];

    files.all.".config/qView/qView.conf".weakCopy = confFile;
  };
}
