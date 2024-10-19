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

      # wineWowPackages.stable  # 32-bit and 64-bit stable
      # wineWowPackages.staging # 32-bit and 64-bit cutting edge
      # wine64                  # 64-bit only
      wine                      # 32-bit only
      winetricks                # support all versions
    ];

    # Set the correct category
    services.xdg.menu.itemOverrides = [
      {
        categories = "System";
        source = "${pkgs.winetricks}/share/applications/winetricks.desktop";
      }
    ];
  };
}
