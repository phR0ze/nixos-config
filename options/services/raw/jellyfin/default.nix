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
      # - openFirewall opens TCP 8096,8920 and UDP 1900,7359 (discovery). Left closed when fronted
      #   by services.raw.caddy on the same host — Caddy reaches it over loopback, and LAN clients
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
    })

    # Contribute a proxy entry to services.raw.caddy.proxies rather than requiring it be listed
    # separately in the machine's configuration.nix
    (lib.mkIf (cfg.enable && cfg.subdomain != null) {
      services.raw.caddy.proxies = [ { inherit (cfg) subdomain port; } ];
    })

    # Ensure network.xml has Caddy (127.0.0.1) as a known proxy (trusts its X-Forwarded-For header)
    # and binds only to loopback, once fronted by services.raw.caddy, matching openFirewall being
    # closed above.
    #
    # Deliberately not a files.any copy/link here — those only know how to replace the whole file or
    # symlink it, and Jellyfin owns network.xml's schema (it adds/renames fields across releases,
    # and rewrites the file itself when settings change via the admin UI). A blanket overwrite would
    # either clobber fields we don't know about or need updating in lockstep with every Jellyfin
    # release. Instead: bootstrap a full default only if the file doesn't exist yet (first install),
    # otherwise surgically patch just the two nodes this hardening cares about with xmlstarlet,
    # leaving everything else (including fields added by newer Jellyfin versions) untouched. If a
    # future release renames/restructures those nodes, the edit fails loudly during activation
    # rather than silently dropping unrelated settings.
    (lib.mkIf (cfg.enable && cfg.subdomain != null) {
      environment.systemPackages = [ pkgs.xmlstarlet ];

      system.activationScripts.jellyfin-network-xml = lib.stringAfter [ "users" "groups" ] ''
        networkXml=/var/lib/jellyfin/config/network.xml
        if [ -f "$networkXml" ]; then
          if ! ${pkgs.xmlstarlet}/bin/xmlstarlet ed --inplace \
              -u "/NetworkConfiguration/KnownProxies" -v "127.0.0.1" \
              -u "/NetworkConfiguration/LocalNetworkAddresses" -v "127.0.0.1" \
              "$networkXml"; then
            echo "WARNING: services.raw.jellyfin could not patch $networkXml (KnownProxies/LocalNetworkAddresses) — Jellyfin's network.xml schema may have changed; set these manually via Dashboard > Networking" >&2
          fi
          chown jellyfin:jellyfin "$networkXml"
        else
          install -D -m 0644 -o jellyfin -g jellyfin ${pkgs.writeText "jellyfin-network.xml" ''
            <?xml version="1.0" encoding="utf-8"?>
            <NetworkConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
              <BaseUrl />
              <EnableHttps>false</EnableHttps>
              <RequireHttps>false</RequireHttps>
              <CertificatePath />
              <CertificatePassword />
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
          ''} "$networkXml"
        fi
      '';
    })
  ];
}
