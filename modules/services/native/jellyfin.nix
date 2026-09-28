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
  cfg = config.services.native.jellyfin;
in
{
  options = {
    services.native.jellyfin = {
      enable = lib.mkEnableOption "Install and configure Jellyfin server";

      port = lib.mkOption {
        type = lib.types.port;
        default = 8096;
        description = lib.mdDoc "Port the Jellyfin web/API server listens on.";
      };

      subdomain = lib.mkOption {
        description = lib.mdDoc ''
          Front this service with `services.native.caddy` at `<subdomain>.<domain>` — gets a hostname
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

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # Enable Jellyfin media server
      # - openFirewall opens TCP 8096,8920 and UDP 1900,7359 (discovery). Left closed when fronted
      #   by services.native.caddy on the same host — Caddy reaches it over loopback, and LAN clients
      #   go through Caddy's TLS instead of hitting Jellyfin's HTTP port directly.
      services.jellyfin = {
        enable = true;
        openFirewall = cfg.subdomain == null;
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

      # Install the file if it doesn't exist
      files.any."/var/lib/jellyfin/config/network.xml" = {
        user = "jellyfin";
        group = "jellyfin";
        weakCopy = ''
          <?xml version="1.0" encoding="utf-8"?>
          <NetworkConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
            <BaseUrl />
            <EnableHttps>false</EnableHttps>
            <RequireHttps>false</RequireHttps>
            <InternalHttpPort>${toString cfg.port}</InternalHttpPort>
            <InternalHttpsPort>8920</InternalHttpsPort>
            <PublicHttpPort>${toString cfg.port}</PublicHttpPort>
            <PublicHttpsPort>8920</PublicHttpsPort>
            <AutoDiscovery>true</AutoDiscovery>
            <EnableUPnP>false</EnableUPnP>
            <EnableIPv4>true</EnableIPv4>
            <EnableIPv6>false</EnableIPv6>
            <EnableRemoteAccess>false</EnableRemoteAccess>
            <LocalNetworkSubnets />
            <LocalNetworkAddresses>127.0.0.1</LocalNetworkAddresses>
            <KnownProxies>127.0.0.1</KnownProxies>
            <IgnoreVirtualInterfaces>true</IgnoreVirtualInterfaces>
            <VirtualInterfaceNames>
              <string>veth</string>
            </VirtualInterfaceNames>
            <EnablePublishedServerUriByRequest>false</EnablePublishedServerUriByRequest>
            <PublishedServerUriBySubnet />
            <RemoteIPFilter />
            <IsRemoteIPFilterBlacklist>false</IsRemoteIPFilterBlacklist>
          </NetworkConfiguration>
        '';
      };
    }

    # Add a caddy proxy config for DNS subdomain resolution
    (lib.mkIf (cfg.subdomain != null) {
      services.native.caddy.proxies = [ { inherit (cfg) subdomain port; } ];
    })
  ]);
}
