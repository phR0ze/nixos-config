# GitHub CLI (gh)
# GitHub's official command line tool for working with GitHub.
#
# ### Details
# - Installs the `gh` package
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.apps.dev.gh;
in
{
  options = {
    apps.dev.gh = {
      enable = lib.mkEnableOption "Install GitHub CLI (gh)";
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ gh ];
  };
}
