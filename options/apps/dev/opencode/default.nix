# OpenCode
# 
# ### Purpose
# - Exposes OpenCode configuration options to the flake
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.apps.dev.opencode;
in
{
  options = {
    apps.dev.opencode = {
      enable = lib.mkEnableOption "Install and configure OpenCode";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {

      # Install supporting packages
      environment.systemPackages = [
        (pkgs.callPackage ./package.nix {})             # Call the local package
      ];
    })
  ];
}
