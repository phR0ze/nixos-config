# Synology Drive client configuration
#
# ### Configuration
# - Autostarts after login
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.services.raw.synology-drive-client;
in
{
  options = {
    services.raw.synology-drive-client = {
      enable = lib.mkEnableOption "Configure Synology Drive client";
      autostart = lib.mkOption {
        description = lib.mdDoc "Autostart once logged in";
        type = types.bool;
        default = true;
      };
    };
  };
 
  config = lib.mkMerge [

    # Install
    (lib.mkIf cfg.enable {
      environment.systemPackages = [
        pkgs.synology-drive-client
      ];
    })

    # Configure autostart after login
    (lib.mkIf (cfg.enable && cfg.autostart) {
      environment.etc."xdg/autostart/synology-drive-client.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Terminal=false
        Exec=${pkgs.synology-drive-client}/bin/synology-drive
      '';
    })
  ];
}
