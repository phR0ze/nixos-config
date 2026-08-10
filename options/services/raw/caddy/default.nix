# Caddy reverse proxy
# - https://caddyserver.com/docs/
#
# ### Description
# Fronts one or more localhost-bound homelab services with Caddy-managed TLS. Each proxied service
# gets its own HTTPS port using Caddy's `tls internal` directive, which auto-generates and manages
# certificates signed by a local, Caddy-owned CA — no public domain, ACME, or port 80 exposure
# required. The original HTTP port each service already listens on is left untouched, so this is
# purely additive.
#
# ### Deployment notes
# 1. Add an entry to `proxies` per backend service: `{ name = "vaultwarden"; port = 8222; }`. It'll
#    be reachable at `https://<machine.net.nic0.ip>:9222` (defaults to `port + 1000`; override with
#    `httpsPort`). Site blocks bind to `machine.net.nic0.ip` rather than a bare port — Caddy needs a
#    concrete host to match the incoming SNI against, or the TLS handshake fails outright.
# 2. The first connection from each client will show an untrusted-certificate warning, since the CA
#    is unique to this host. Export it once and trust it on your devices to stop seeing that:
#      sudo find /var/lib/caddy -name root.crt
# 3. This is a stopgap for LAN-local HTTPS. Once a real reverse proxy fronts these services from the
#    outside (e.g. Pangolin), point it at the plain HTTP ports directly and this module can be
#    disabled.
# --------------------------------------------------------------------------------------------------
{ config, lib, ... }: with lib.types;
let
  cfg = config.services.raw.caddy;

  # Caddy's automatic HTTPS needs a concrete host in the site address to know which cert to
  # issue/select — a bare ":<port>" address gives it nothing to match incoming SNI against, and the
  # TLS handshake fails (SSL_ERROR_INTERNAL_ERROR_ALERT) even with a trusted CA. Bind to the
  # machine's actual LAN IP instead, pulled from machine config rather than hardcoded.
  bindHost = lib.head (lib.splitString "/" config.machine.net.nic0.ip);

  httpsPortOf = p: if p.httpsPort != null then p.httpsPort else p.port + 1000;
in
{
  options = {
    services.raw.caddy = {
      enable = lib.mkEnableOption "Install and configure Caddy as a local TLS-terminating reverse proxy";

      proxies = lib.mkOption {
        type = listOf (submodule {
          options = {
            name = lib.mkOption {
              type = types.str;
              description = lib.mdDoc "Label for this proxy entry, used only in Caddy's logs.";
            };

            port = lib.mkOption {
              type = types.port;
              description = lib.mdDoc "Backend HTTP port on localhost this proxy forwards to.";
            };

            httpsPort = lib.mkOption {
              type = types.nullOr types.port;
              default = null;
              description = lib.mdDoc ''
                HTTPS port Caddy listens on for this proxy. Defaults to `port + 1000` when unset.
              '';
            };
          };
        });
        default = [ ];
        example = [{ name = "vaultwarden"; port = 8222; }];
        description = lib.mdDoc "Backend services to front with Caddy-managed local TLS.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;

      # Caddy's automatic HTTPS silently opens an HTTP->HTTPS redirect listener on :80 for any site
      # using TLS, even though every virtualHost below only declares its own https port. Disable it so
      # Caddy never touches port 80, matching this module's "no port 80 exposure" design.
      globalConfig = ''
        auto_https disable_redirects
      '';

      virtualHosts = lib.listToAttrs (map
        (p: lib.nameValuePair "${bindHost}:${toString (httpsPortOf p)}" {
          extraConfig = ''
            tls internal
            reverse_proxy 127.0.0.1:${toString p.port}
          '';
        })
        cfg.proxies);
    };

    networking.firewall.allowedTCPPorts = map httpsPortOf cfg.proxies;
  };
}
