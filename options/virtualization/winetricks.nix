# Winetricks ooptions
#
# ### Details
# - Automation for installing missing DLLs and configuration for Wine
# - No options available in nixos
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.programs.winetricks;

in
{
  options = {
    programs.winetricks = {
      enable = lib.mkEnableOption "Install and configure winetricks";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [
      wine
      winetricks
    ];

    # Set the correct category for steam
    services.xdg.menu.itemOverrides = [
      {
        categories = "System";
        source = "${pkgs.winetricks}/share/applications/winetricks.desktop";
      }
    ];
  };
}
