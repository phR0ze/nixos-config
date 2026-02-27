# Gemini CLI
#
# ### Purpose
# - Exposes Gemini CLI configuration options to the flake
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.apps.dev.gemini;
in
{
  options = {
    apps.dev.gemini = {
      enable = lib.mkEnableOption "Install and configure Gemini CLI";
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
