# Claude Code
# 
# ### Purpose
# - Exposes Claude Code configuration options to the flake
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.apps.dev.claude;
in
{
  options = {
    apps.dev.claude = {
      enable = lib.mkEnableOption "Install and configure Claude Code";
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
