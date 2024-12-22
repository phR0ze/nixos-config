# Steam ooptions
#
# ### Details
# - options nixos/modules/programs/steam.nix
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.programs.steam;

in
{
  config = lib.mkIf (cfg.enable) {

    # Set the correct category for steam
    services.xdg.menu.itemOverrides = [
      {
        categories = "Games";
        source = "${cfg.package}/share/applications/steam.desktop";
      }
    ];
  };
}
