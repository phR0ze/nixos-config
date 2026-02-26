# GitHub CLI (gh)
# GitHub's official command line tool for working with GitHub.
#
# ### Details
# - Installs the `gh` package
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.development.gh;
in
{
  options = {
    development.gh = {
      enable = lib.mkEnableOption "Install GitHub CLI (gh)";
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ gh ];
  };
}
