# Evince options
#
# ### Details
# - Exists in nixos/modules/programs/evnice.nix but has no options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.programs.evince;

in
{
  config = lib.mkIf (cfg.enable) {
    services.xdg.menu.itemOverrides = [
      {
        categories = "Office";
        source = "${cfg.package}/share/applications/org.gnome.Evince.desktop";
      }
    ];
  };
}
