# Evince options
#
# ### Details
# - Exists in nixos/modules/programs/evnice.nix but has no options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.office.evince;
in
{
  options = {
    apps.office.evince = {
      enable = lib.mkEnableOption "Install and configure evince";
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ evince ];

    services.xdg.menu.itemOverrides = [
      {
        categories = "Office";
        source = "${cfg.package}/share/applications/org.gnome.Evince.desktop";
      }
    ];
  };
}
