# Protontricks ooptions
#
# ### Details
# - A simple wrapper for running Winetricks commands for Proton-enabled games
# - No options available in nixos
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.apps.games.protontricks;
in
{
  options = {
    apps.games.protontricks = {
      enable = lib.mkEnableOption "Install and configure protontricks";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    programs.steam.protontricks.enable = true;

    # Set the correct category for steam
    services.xdg.menu.itemOverrides = [
      {
        categories = "Games";
        source = "${pkgs.protontricks}/share/applications/protontricks.desktop";
      }
    ];
  };
}
