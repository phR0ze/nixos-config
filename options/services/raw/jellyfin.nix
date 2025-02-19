# Jellyfin
#
# ### Description
# Jellyfin is a Free Software Media System that puts you in control of managing and streaming your 
# media. It's an alternative to the proprietary Emby and Plex.
#
# - Cross-platform client support: MacOS, Windows, Linux and Android
# - Remote control of Kodi or Jellyfin Media Player or Jellyfin MPV Shim via mobile app
#
# ### Directories
# - /var/cache/jellyfin
# - /var/lib/jellyfin
# - /var/lib/jellyfin/config
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.services.raw.jellyfin;
  machine = config.machine;
in
{
  options = {
    services.raw.jellyfin = {
      enable = lib.mkEnableOption "Install and configure Jellyfin server";
    };
  };
 
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
   
      # Enable Jellyfin media server
      services.jellyfin = {
        enable = true;
        openFirewall = true;        # TCP: 8096,8920; UDP: 1900,7359
      };

      environment.systemPackages = [
        pkgs.jellyfin               # Jellyfin core
        pkgs.jellyfin-web           # Jellyfin web client support
        pkgs.jellyfin-ffmpeg        # Jellyfin codecs bundle
      ];    
    })
  ];
}
