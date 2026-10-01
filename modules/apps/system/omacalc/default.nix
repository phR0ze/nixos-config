# omacalc
#
# ### Purpose
# - Installs omacalc, Omarchy's simple Qt Quick calculator
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.apps.system.omacalc;
in
{
  options = {
    apps.system.omacalc = {
      enable = lib.mkEnableOption "Install omacalc calculator";
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [
      (pkgs.callPackage ./package.nix {})
    ];
  };
}
