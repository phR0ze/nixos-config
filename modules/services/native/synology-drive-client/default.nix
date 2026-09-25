# Synology Drive client configuration
#
# ### Configuration
# - Autostarts after login
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.native.synology-drive-client;
in
{
  options = {
    services.native.synology-drive-client = {
      enable = lib.mkEnableOption "Configure Synology Drive client";
      autostart = lib.mkOption {
        description = lib.mdDoc "Autostart once logged in";
        type = types.bool;
        default = true;
      };
    };
  };
 
  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      environment.systemPackages = [
        pkgs.synology-drive-client
      ];
    }

    # Configure autostart after login
    (lib.mkIf cfg.autostart {
      environment.etc."xdg/autostart/synology-drive-client.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Terminal=false
        Exec=sudo ${pkgs.synology-drive-client}/bin/synology-drive
      '';
    })
  ]);
}
