# Caddy reverse proxy
# - https://caddyserver.com/docs/
# - https://caddyserver.com/docs/modules/dns.providers
#
# ### Description
# Fronts homelab services with TLS on a `*.<zone>` site per entry in `domains` on port 443, routed
# by hostname, using one wildcard certificate per zone from a Cloudflare DNS-01 challenge. Uses
# upstream `caddy` with the caddy-dns/cloudflare plugin via `withPlugins` (see package.nix).
#
# ### Deployment notes
# 1. Cloudflare: per zone, create a wildcard `*.<zone>` DNS record (non-proxied, pointing anywhere)
#    and a scoped API token (Zone:DNS:Edit + Zone:Zone:Read). Store the token in the host's
#    `secrets.enc.yaml` under the zone's `cloudflareApiTokenSecretRef` (default
#    `caddy/cloudflareApiToken`, so one token covering every zone is enough). A zone with its own
#    token sets `host.services.native.caddy.domains.<zone>.cloudflareApiTokenSecretRef` in
#    `args.enc.yaml`.
# 2. Host: `services.native.caddy.enable = true;` - `sopsFile` and one `domains` entry per
#    `host.network.domains` zone are forwarded by `modules/default.nix`, keeping zones out of
#    tracked files.
# 3. Proxies: apps add their own entry to `domains.<zone>.proxies` via their `subdomain`, `domains`
#    and `whichDomains` options - the primary (first) zone only by default, every zone with
#    `whichDomains = "all"`. Backends on other machines go in `host.services.native.caddy.proxies`
#    in `args.enc.yaml` (same fields plus optional `whichDomains`) to keep LAN IPs untracked; the
#    list is zone-less because sops leaves keys, e.g. `domains.<zone>`, in plaintext.
# 4. Pangolin: with `services.oci.newt` on this host, resources target
#    `https://host.containers.internal:443` and keep their public name end to end, so Caddy must
#    serve that subdomain on the Pangolin server's zone (see newt.nix's "Blueprints", which asserts
#    it). Each enabled Newt instance's IP is added to `trustedProxies` automatically by
#    `modules/default.nix`.
# 5. DNS-01 checks use Cloudflare's resolvers because AdGuard's `*.<primary zone>` rewrite would hide
#    the `_acme-challenge` TXT record.
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.native.caddy;

  zones = lib.attrValues cfg.domains;

  # A zone's hostname-routed proxies (`subdomain` set)
  proxiesOf = zone: lib.filter (p: p.subdomain != null) zone.proxies;

  # Env var carrying a zone's Cloudflare token, e.g. `CF_API_TOKEN_EXAMPLE_COM`
  tokenVar = zone: "CF_API_TOKEN_" + lib.toUpper (lib.replaceStrings [ "." "-" ] [ "_" "_" ] zone.name);
  tokenVars = map tokenVar zones;
  duplicateTokenVars = lib.unique (lib.filter (v: lib.count (x: x == v) tokenVars > 1) tokenVars);

  # Subdomains used by more than one proxy on the same zone, which would define the same matcher twice
  duplicateSubdomains = lib.concatMap (zone: map (sub: "${sub}.${zone.name}")
    (lib.attrNames (lib.filterAttrs (_: ps: lib.length ps > 1)
      (lib.groupBy (p: p.subdomain) (proxiesOf zone))))) zones;

  hasProxies = lib.any (zone: proxiesOf zone != [ ]) zones;

  # Plain HTTP to the backend, or HTTPS without certificate checks for self-signed LAN appliances
  reverseProxy = p: if p.tlsSkipVerify then ''
    reverse_proxy https://${p.host}:${toString p.port} {
          transport http {
            tls_insecure_skip_verify
          }
        }'' else "reverse_proxy ${p.host}:${toString p.port}";

  # One `*.<zone>` site per zone with only that zone's proxies, each with its own wildcard
  # certificate requested with that zone's own token
  wildcardSite = zone: lib.nameValuePair "*.${zone.name}" {
    extraConfig = ''
      tls {
        dns cloudflare {env.${tokenVar zone}}
        resolvers 1.1.1.1 1.0.0.1
      }

      # `?` only sets the header if the backend didn't; HSTS is always set
      header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        ?X-Content-Type-Options "nosniff"
        ?X-Frame-Options "SAMEORIGIN"
        ?Referrer-Policy "strict-origin-when-cross-origin"
        -Server
      }
    '' + lib.concatMapStringsSep "\n" (p: ''
      @${p.subdomain} host ${p.subdomain}.${zone.name}
      handle @${p.subdomain} {
        ${reverseProxy p}
      }
    '') (proxiesOf zone) + ''

      # Unknown subdomains
      handle {
        respond 404
      }
    '';
  };
in
{
  options = {
    services.native.caddy = {
      enable = lib.mkEnableOption "Install and configure Caddy as a local TLS-terminating reverse proxy";

      domains = lib.mkOption {
        type = attrsOf (submodule ({ name, ... }: {
          options = {
            name = lib.mkOption {
              type = types.str;
              default = name;
              description = "The zone, served as a `*.<name>` site with its own wildcard certificate.";
            };

            cloudflareApiTokenSecretRef = lib.mkOption {
              type = types.str;
              default = "caddy/cloudflareApiToken";
              description = ''
                Key within `sopsFile` holding this zone's Cloudflare API token (Zone:DNS:Edit +
                Zone:Zone:Read). Zones sharing a key share the token.
              '';
            };

            proxies = lib.mkOption {
              type = listOf (submodule { imports = [ (import ../../../types/caddy_proxy.nix { inherit lib; }) ]; });
              default = [ ];
              example = [{ subdomain = "vault"; port = 8222; }];
              description = ''
                Backends served as `<subdomain>.<name>`. Filled in by apps' own `subdomain`/`domains`
                options and by `host.services.native.caddy.proxies` in build-time args.
              '';
            };
          };
        }));
        default = { };
        description = ''
          Zones Caddy serves, keyed by zone. One entry per `host.network.domains` zone is forwarded by
          `modules/default.nix`; apps add their proxies to the zones they're served on.
        '';
      };

      sopsFile = lib.mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "./secrets.enc.yaml";
        description = ''
          sops file holding the Cloudflare API token(s). Forwarded from `host.sopsFile`.
        '';
      };

      cloudflarePluginTag = lib.mkOption {
        type = types.str;
        default = "v0.2.4";
        description = ''
          caddy-dns/cloudflare release tag compiled into Caddy. Changing it requires updating
          `cloudflarePluginHash` too - see README.md.
        '';
      };

      cloudflarePluginHash = lib.mkOption {
        type = types.str;
        default = "sha256-hEHgAG0F0ozHRAPuxEqLyTATBrE+pajeXDiSNwniorg=";
        description = ''
          Hash of Caddy's source with `cloudflarePluginTag` vendored in. Changes whenever the tag or
          nixpkgs' caddy version does.
        '';
      };

      trustedProxies = lib.mkOption {
        type = listOf str;
        default = [ ];
        example = [ "192.168.1.10/32" ];
        description = ''
          Upstream proxy IPs/CIDRs (e.g. Pangolin's Newt) whose `X-Forwarded-For` is trusted, so
          backends see real client IPs. Forwarded from `host.services.native.caddy.trustedProxies`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = cfg.sopsFile != null;
        message = "services.native.caddy requires 'sopsFile', normally forwarded from 'host.sopsFile'";
      }
      { assertion = zones != [ ];
        message = "services.native.caddy requires at least one zone in 'domains', normally forwarded from 'host.network.domains'";
      }
      { assertion = duplicateTokenVars == [ ];
        message = "services.native.caddy: zones whose token env var names collide: ${lib.concatStringsSep ", " duplicateTokenVars}";
      }
      { assertion = duplicateSubdomains == [ ];
        message = "services.native.caddy: host(s) claimed by more than one proxy: ${lib.concatStringsSep ", " duplicateSubdomains}";
      }
    ];

    # One token env var per zone as an EnvironmentFile. Restart, not reload: env vars are only read
    # at start.
    secret.templates."caddy-cloudflare" = {
      filemode = "0400";
      content = lib.concatMapStrings (zone: ''
        ${tokenVar zone}=${config.secret.ref.${zone.cloudflareApiTokenSecretRef}}
      '') zones;
      secrets = lib.genAttrs (lib.unique (map (zone: zone.cloudflareApiTokenSecretRef) zones))
        (_: { sopsFile = cfg.sopsFile; });
      restartUnits = [ "caddy.service" ];
    };

    services.caddy = {
      enable = true;

      package = pkgs.callPackage ./package.nix {
        inherit (cfg) cloudflarePluginTag;
        hash = cfg.cloudflarePluginHash;
      };

      # - auto_https disable_redirects: keep Caddy off port 80; DNS-01 doesn't need it
      # - default_sni: Pangolin's HTTPS resources connect without SNI (fosrl/pangolin#207), so
      #   assume a hostname that selects a wildcard cert (any zone's will do); routing still uses
      #   the Host header
      globalConfig = ''
        auto_https disable_redirects
      '' + lib.optionalString (zones != [ ]) ''
        default_sni fallback.${(lib.head zones).name}
      '' + lib.optionalString (cfg.trustedProxies != [ ]) ''
        servers {
          trusted_proxies static ${lib.concatStringsSep " " cfg.trustedProxies}
          # Right-to-left: the client IP is the first untrusted hop, not a client-supplied leftmost
          trusted_proxies_strict
        }
      '';

      environmentFile = config.secret.templates."caddy-cloudflare".path;

      virtualHosts = lib.optionalAttrs hasProxies (lib.listToAttrs (map wildcardSite zones));
    };

    # UDP for HTTP/3
    networking.firewall.allowedTCPPorts = lib.optional hasProxies 443;
    networking.firewall.allowedUDPPorts = lib.optional hasProxies 443;

    # Fail the build if the generated Caddyfile doesn't validate. The dummy tokens are never used, and
    # the log dir is swapped for $TMPDIR since `validate` opens the log files.
    system.checks = [
      (pkgs.runCommand "caddy-config-validate" { } ''
        export HOME=$TMPDIR XDG_DATA_HOME=$TMPDIR XDG_CONFIG_HOME=$TMPDIR
        ${lib.concatMapStrings (v: "export ${v}=0000000000000000000000000000000000000000\n") tokenVars}        sed 's|${config.services.caddy.logDir}|'"$TMPDIR"'|g' ${config.services.caddy.configFile} > Caddyfile
        ${lib.getExe config.services.caddy.package} validate --config Caddyfile --adapter caddyfile
        touch $out
      '')
    ];
  };
}
