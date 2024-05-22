# Protontricks ooptions
#
# ### Details
# - A simple wrapper for running Winetricks commands for Proton-enabled games
# - No options available in nixos
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.programs.protontricks;

in
{
  options = {
    programs.protontricks = {
      enable = lib.mkEnableOption "Install and configure protontricks";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [
      protontricks
    ];

    # Set the correct category for steam
    services.xdg.menu.itemOverrides = [
      {
        categories = "Games";
        source = "${pkgs.protontricks}/share/applications/protontricks.desktop";
      }
    ];
  };
}
