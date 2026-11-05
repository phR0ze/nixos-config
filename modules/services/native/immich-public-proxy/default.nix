# Immich Public Proxy
# - https://github.com/alangrainger/immich-public-proxy
# - https://docs.ipp.nz
#
# ### Description
# Shares Immich albums and photos publicly without exposing Immich itself. Visitors only ever reach
# this proxy, which serves nothing but `/share/<key>` links created in Immich and fetches exactly
# what that key covers from Immich, read-only. It has no index, login or API passthrough, so a
# visitor can't list or guess other shares.
#
# ### Deployment notes
# 1. Wraps upstream's `services.immich-public-proxy` with the v4 package from ./package.nix
#    (nixpkgs still ships 3.x). It runs as a sandboxed `DynamicUser` that may only talk to
#    loopback (`IPAddressAllow = localhost`). It reaches Immich at `immichUrl`, forwarded as
#    `http://127.0.0.1:<port>` when `services.native.immich` runs on the same host.
# 2. Caddy serves it at `<subdomain>.<zone>` on the zones picked by `whichDomains`. Through
#    Pangolin it's a public resource **without SSO**, since visitors have no account:
#    `photos: { sso: false }` in the Newt instance's `pangolin.resources`
#    (modules/services/oci/newt.nix "Blueprints"). Immich's own `immich` resource keeps its SSO.
# 3. Access is per share link: each link is created by one Immich user, carries a random key and
#    has its own password and expiry, which the proxy prompts for. Patched Immich builds require
#    the password and refuse custom URLs (modules/services/native/immich/package.nix, patches 003
#    and 004). Custom-URL `/s/<slug>` links return 404 here regardless (`allowSlugLinks = false`),
#    since a slug is guessable where the random key isn't.
# 4. `publicUrl` is forwarded from the Newt resource on the same subdomain when there is one,
#    otherwise it's `https://<subdomain>.<primary domain>`. It's also forwarded as Immich's
#    `externalDomain`, so share links point here instead of at Immich.
#
# ### Verify
#  systemctl status immich-public-proxy
#  curl -sf http://127.0.0.1:<port>/share/healthcheck   # 200 once Immich answers
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.services.native.immich-public-proxy;
in
{
  options = {
    # `domains`/`whichDomains`: which Caddy zones it's served on, see modules/types/caddy_domains.nix
    services.native.immich-public-proxy = (import ../../../types/caddy_domains.nix { inherit lib; }) // {
      enable = lib.mkEnableOption "Install and configure Immich Public Proxy";

      port = lib.mkOption {
        type = types.nullOr types.port;
        default = null;
        description = "Loopback port the proxy listens on, behind Caddy.";
      };

      subdomain = lib.mkOption {
        type = types.str;
        default = "photos";
        description = "Subdomain Caddy serves the proxy at on each zone picked by `whichDomains`.";
      };

      immichUrl = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "http://127.0.0.1:2283";
        description = ''
          Loopback URL of the Immich server. Forwarded by `modules/default.nix` when
          `services.native.immich` runs on this host. Only loopback is reachable (see note 1).
        '';
      };

      publicUrl = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "https://photos.example.com";
        description = ''
          The proxy's public base URL (`PUBLIC_BASE_URL`), also Immich's `externalDomain`.
          Forwarded from the Newt resource on `subdomain`, if any, otherwise
          `https://<subdomain>.<primary domain>`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = cfg.port != null;
        message = "services.native.immich-public-proxy requires 'port' to be set"; }
      { assertion = cfg.immichUrl != null;
        message = "services.native.immich-public-proxy requires 'immichUrl', forwarded automatically when services.native.immich is enabled on this host"; }
      { assertion = cfg.publicUrl != null;
        message = "services.native.immich-public-proxy requires 'publicUrl', forwarded automatically from 'host.network.domains'"; }
      (f.caddyDomainsAssert "native.immich-public-proxy" cfg)
    ];

    services.immich-public-proxy = {
      enable = true;
      package = pkgs.callPackage ./package.nix { };
      port = cfg.port;
      immichUrl = cfg.immichUrl;
      # Custom-URL (`/s/<slug>`) links are guessable, so only random-key `/share/<key>` links work
      settings.ipp.allowSlugLinks = false;
    };

    systemd.services.immich-public-proxy = {
      environment.PUBLIC_BASE_URL = cfg.publicUrl;
      serviceConfig = {
        # Loopback only: Caddy in, Immich out (note 1)
        IPAddressDeny = "any";
        IPAddressAllow = "localhost";
        ProtectSystem = "strict";
      };
    };

    services.native.caddy.enable = lib.mkDefault true;
    services.native.caddy.domains = f.caddyProxies cfg [ { inherit (cfg) subdomain port; } ];
  };
}
