# Jellyfin clients
# Simple wrapper around the Jellyfin clients to optionally provide autostart for MPV Shim
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.media.jellyfin;
in
{
  options = {
    apps.media.jellyfin = {
      enable = lib.mkEnableOption "Install and configure Jellyfin clients";
      autostartMPVShim = lib.mkOption {
        description = lib.mdDoc "Autostart the Jellyfin MPV Shim";
        type = types.bool;
        default = false;
      };
    };
  };

  config = lib.mkMerge [

    (lib.mkIf cfg.enable {
      environment.systemPackages = [
        pkgs.jellyfin-media-player    # Crossplatform desktop client
      ];
    })

    # Install and autostart with delay to allow the server to start
    (lib.mkIf (cfg.enable && cfg.autostartMPVShim) {
      environment.systemPackages = [
        pkgs.jellyfin-mpv-shim         # Casting support to MPV via Jellyfin mobile and web apps
      ];
      environment.etc."xdg/autostart/jellyfin-mpv-shim.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Terminal=false
        Exec=bash -c "sleep 5 && ${pkgs.jellyfin-mpv-shim}/bin/jellyfin-mpv-shim"
      '';
    })
  ];
}
