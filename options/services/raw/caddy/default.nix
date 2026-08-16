# Caddy reverse proxy
# - https://caddyserver.com/docs/
# - https://caddyserver.com/docs/modules/dns.providers
#
# ### Description
# Fronts one or more homelab services with Caddy-managed TLS. Each proxied service
# gets its own HTTPS port and a real, publicly-trusted Let's Encrypt certificate obtained via a
# Cloudflare DNS-01 challenge (see `options/services/raw/caddy/package.nix` for the
# caddy-dns/cloudflare build). The original HTTP port each service already listens on is left
# untouched, so this is purely additive.
#
# ### Deployment notes
# 1. Add an entry to `proxies` per backend service: `{ subdomain = "vault"; port = 8222; }`. It'll be
#    reachable at `https://vault.<domain>` (defaults to port 443; set `httpsPort` to put this proxy on
#    a non-standard port instead). Multiple proxies can share port 443 — Caddy multiplexes by SNI, so
#    site blocks bind to `<subdomain>.<domain>` rather than a bare port.
# 2. Set `domain = config.machine.domain;` in the machine's `configuration.nix` (machine.domain comes
#    from the `domain` key in `args.enc.json`/`args.nix`, keeping the literal zone name out of tracked
#    files). DNS-01 only proves control of the zone — it doesn't create routing, so each
#    `<subdomain>.<domain>` still needs an actual DNS record in Cloudflare (can be a greyed-out/
#    non-proxied A/CNAME pointing anywhere, since clients reach this host directly on the LAN).
# 3. Add a scoped Cloudflare API token (Zone:DNS:Edit + Zone:Zone:Read for the zone(s) in question —
#    not the Global API Key) to a `secrets.enc.yaml` under the `caddy.cloudflareApiToken` key, then
#    point `secrets` at it from the machine's `configuration.nix`:
#      services.raw.caddy = {
#        enable = true;
#        secrets = ./secrets.enc.yaml;
#        ...
#      };
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.raw.caddy;

  hostOf = p: "${p.subdomain}.${cfg.domain}";
in
{
  options = {
    services.raw.caddy = {
      enable = lib.mkEnableOption "Install and configure Caddy as a local TLS-terminating reverse proxy";

      secrets = lib.mkOption {
        type = types.path;
        example = "./secrets.enc.yaml";
        description = lib.mdDoc ''
          Path to the sops-encrypted file holding the `caddy.cloudflareApiToken` secret. Declared here
          so `sops.secrets."caddy/cloudflareApiToken"` doesn't need to be repeated in every machine's
          `configuration.nix`.
        '';
      };

      domain = lib.mkOption {
        type = types.str;
        example = "example.com";
        description = lib.mdDoc ''
          Cloudflare-managed zone used for certificate issuance. Each proxy is reachable at
          `<subdomain>.<domain>`. Set to `config.machine.domain` in the machine's `configuration.nix`
          rather than a literal string, to avoid committing the domain in plaintext.
        '';
      };

      proxies = lib.mkOption {
        type = listOf (submodule { imports = [ (import ../../../types/caddy_proxy.nix { inherit lib; }) ]; });
        default = [ ];
        example = [{ subdomain = "vault"; port = 8222; }];
        description = lib.mdDoc ''
          Backend services to front with Caddy-managed local TLS. Populated automatically from any
          enabled app's own `caddy` option (e.g. `services.raw.vaultwarden.caddy`) — only add entries
          here directly for apps that don't expose one.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."caddy/cloudflareApiToken" = {
      sopsFile = cfg.secrets;
    };

    # Wraps the bare-token secret in a KEY=VALUE line sops-nix assembles at activation time (into
    # /run/secrets-for-users or /run/secrets, mode 0400), suitable for systemd's EnvironmentFile=.
    sops.templates."caddy-cloudflare.env".content = ''
      CF_API_TOKEN=${config.sops.placeholder."caddy/cloudflareApiToken"}
    '';

    services.caddy = {
      enable = true;

      # Built with the caddy-dns/cloudflare module compiled in (see package.nix), providing the `dns
      # cloudflare` directive used below for DNS-01 ACME challenges.
      package = pkgs.callPackage ./package.nix { };

      # Caddy's automatic HTTPS silently opens an HTTP->HTTPS redirect listener on :80 for any site
      # using TLS, even though every virtualHost below only declares its own https port. Disable it so
      # Caddy never touches port 80, matching this module's "no port 80 exposure" design. DNS-01
      # doesn't need inbound HTTP challenge traffic either, so nothing is lost.
      globalConfig = ''
        auto_https disable_redirects
      '';

      # Cloudflare API token handed to the caddy-dns/cloudflare module via an env var, sourced from
      # the sops-nix-rendered template above rather than embedding the secret in the Caddyfile.
      environmentFile = config.sops.templates."caddy-cloudflare.env".path;

      virtualHosts = lib.listToAttrs (map
        (p: lib.nameValuePair "${hostOf p}:${toString (p.httpsPort)}" {
          extraConfig = ''
            tls {
              dns cloudflare {env.CF_API_TOKEN}
            }
            reverse_proxy 127.0.0.1:${toString p.port}
          '';
        })
        cfg.proxies);
    };

    networking.firewall.allowedTCPPorts = map (p: p.httpsPort) cfg.proxies;

    # The NixOS caddy module runs the service as an unprivileged user with no capabilities, so
    # binding any proxy's httpsPort below 1024 (443 by default) needs this granted explicitly.
    systemd.services.caddy.serviceConfig = {
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
    };
  };
}
