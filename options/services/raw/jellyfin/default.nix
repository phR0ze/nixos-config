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
{ config, lib, pkgs, ... }:
let
  cfg = config.services.raw.jellyfin;
in
{
  options = {
    services.raw.jellyfin = {
      enable = lib.mkEnableOption "Install and configure Jellyfin server";

      port = lib.mkOption {
        type = lib.types.port;
        default = 8096;
        description = lib.mdDoc "Port the Jellyfin web/API server listens on.";
      };

      subdomain = lib.mkOption {
        description = lib.mdDoc ''
          Front this service with `services.raw.caddy` at `<subdomain>.<domain>` — gets a hostname
          matcher on Caddy's shared wildcard block, routed to this service's backend. Leave `null`
          to not front this service with Caddy (e.g. if only LAN access via `openFirewall` is
          desired).
        '';
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "jellyfin";
      };
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

      # Add access to hardware acceleration for transcoding
      # - https://wiki.nixos.org/wiki/Immich#Enabling_Hardware_Accelerated_Video_Transcoding
      # - https://jellyfin.org/docs/general/administration/hardware-acceleration/intel#linux-setups
      users.users.jellyfin.extraGroups = [ "video" "render" "users" ];
    })

    # Contribute a proxy entry to services.raw.caddy.proxies rather than requiring it be listed
    # separately in the machine's configuration.nix
    (lib.mkIf (cfg.enable && cfg.subdomain != null) {
      services.raw.caddy.proxies = [ { inherit (cfg) subdomain port; } ];
    })
  ];
}
