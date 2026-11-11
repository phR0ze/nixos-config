# bitwarden configuration
# Bitwarden desktop password manager client
#
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.apps.system.bitwarden;

in
{
  options = {
    apps.system.bitwarden = {
      enable = lib.mkEnableOption "Install and configure the Bitwarden desktop client";
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ bitwarden-desktop ];
  };
}
