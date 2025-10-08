# Evince options
#
# ### Details
# - Exists in nixos/modules/programs/evnice.nix but has no options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.office.evince;
  package = config.programs.evince.package;
in
{
  options = {
    apps.office.evince = {
      enable = lib.mkEnableOption "Install and configure evince";
    };
  };

  config = lib.mkIf (cfg.enable) {
    programs.evince.enable = true;

    system.xdg.menu.itemOverrides = [
      {
        categories = "Office";
        source = "${package}/share/applications/org.gnome.Evince.desktop";
      }
    ];
  };
}
