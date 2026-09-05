# Steam ooptions
#
# ### Details
# - options nixos/modules/programs/steam.nix
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.apps.games.steam;
  package = config.programs.steam.package;
in
{
  options = {
    apps.games.steam = {
      enable = lib.mkEnableOption "Install steam";
    };
  };

  config = lib.mkIf (cfg.enable) {
    programs.steam.enable = true;

    # Set the correct category for steam
    system.xdg.menu.itemOverrides = [
      {
        categories = "Games";
        source = "${package}/share/applications/steam.desktop";
      }
    ];
  };
}
