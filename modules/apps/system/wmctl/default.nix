# wmctl
#
# ### Purpose
# - Installs wmctl for X11 window placement used by desktop keyboard shortcuts
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.apps.system.wmctl;
in
{
  options = {
    apps.system.wmctl = {
      enable = lib.mkEnableOption "Install wmctl window manager control tool";
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [
      (pkgs.callPackage ./package.nix {})
    ];
  };
}
