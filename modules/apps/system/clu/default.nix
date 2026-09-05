# clu
# 
# ### Purpose
# - Exposes clu configuration options to the flake
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.apps.system.clu;
in
{
  options = {
    apps.system.clu = {
      enable = lib.mkEnableOption "Install and configure clu";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      # base.nix global flake overlay makes this work
      pkgs.clu
    ];
  };
}
