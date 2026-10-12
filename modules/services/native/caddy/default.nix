# Caddy reverse proxy
# - https://caddyserver.com/docs/
# - https://caddyserver.com/docs/modules/dns.providers
#
# ### Description
# Fronts homelab services with TLS on a `*.<zone>` site per zone (`primaryDomain` and optionally
# `secondaryDomain`) on port 443, routed by hostname, using one wildcard certificate per zone from a
# Cloudflare DNS-01 challenge. Uses
# upstream `caddy` with the caddy-dns/cloudflare plugin via `withPlugins` (see package.nix).
#
# ### Deployment notes
# 1. Cloudflare: create a wildcard `*.<zone>` DNS record per zone (non-proxied, pointing anywhere) and
#    a scoped API token (Zone:DNS:Edit + Zone:Zone:Read). Store the token in the host's
#    `secrets.enc.yaml` under `caddy/cloudflareApiToken`.
#    `secondaryDomain` gets its own `*.<zone>` site and certificate (DNS-01, same token, so it must
#    cover both zones), serving only the proxies that list it in their `domains`.
#    E.g. a second Pangolin server's domain, so a Host-mode private resource on it (whose TLS
#    reaches Caddy untouched, carrying that domain's SNI) can be served.
# 2. Host: `services.native.caddy.enable = true;` - `sopsFile`, `primaryDomain` (`host.network.domain`)
#    and `secondaryDomain` (`host.services.native.caddy.secondaryDomain` in `args.enc.yaml`) are
#    forwarded from `host.*` by `modules/default.nix`, keeping both zones out of tracked files.
# 3. Proxies: apps add their own entry via their `subdomain` option. Backends on other machines go in
#    `host.services.native.caddy.proxies` in `args.enc.yaml` to keep LAN IPs untracked.
# 4. Pangolin: with `services.oci.newt` on this host, target HTTP resources at
#    `https://host.containers.internal:443` (see newt.nix's "Reaching services behind Caddy").
#    Each enabled Newt instance's IP is added to `trustedProxies` automatically by `modules/default.nix`.
# 5. DNS-01 checks use Cloudflare's resolvers because AdGuard's `*.<primaryDomain>` rewrite would hide
#    the `_acme-challenge` TXT record.
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.native.caddy;

  # Zones served; the primary also serves every proxy without its own `domains`
  domains = [ cfg.primaryDomain ] ++ lib.optional (cfg.secondaryDomain != "") cfg.secondaryDomain;

  wildcardProxies = map (p: p // { domains = if p.domains == null then [ cfg.primaryDomain ] else p.domains; })
    (lib.filter (p: p.subdomain != null) cfg.proxies);

  proxiesOn = domain: lib.filter (p: lib.elem domain p.domains) wildcardProxies;

  # Subdomains used by more than one proxy on the same zone, which would define the same matcher twice
  duplicateSubdomains = lib.concatMap (domain: map (sub: "${sub}.${domain}")
    (lib.attrNames (lib.filterAttrs (_: ps: lib.length ps > 1)
      (lib.groupBy (p: p.subdomain) (proxiesOn domain))))) domains;

  # Proxy domains that are neither zone, which would get no site or certificate
  unknownDomains = lib.subtractLists domains (lib.unique (lib.concatMap (p: p.domains) wildcardProxies));

  # One `*.<domain>` site per zone with only that zone's proxies, each with its own wildcard
  # certificate. The token comes from the same env var for every zone, so it must cover all of them.
  wildcardSite = domain: lib.nameValuePair "*.${domain}" {
    extraConfig = ''
      tls {
        dns cloudflare {env.CF_API_TOKEN}
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
      @${p.subdomain} host ${p.subdomain}.${domain}
      handle @${p.subdomain} {
        reverse_proxy ${p.host}:${toString p.port}
      }
    '') (proxiesOn domain) + ''

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

      primaryDomain = lib.mkOption {
        type = types.str;
        default = "";
        example = "example.com";
        description = ''
          Main Cloudflare zone, served as a `*.<zone>` site with its own wildcard certificate. Proxies
          without their own `domains` are served here only. Forwarded from `host.network.domain`.
        '';
      };

      secondaryDomain = lib.mkOption {
        type = types.str;
        default = "";
        example = "example.org";
        description = ''
          Optional second Cloudflare zone, served as its own `*.<zone>` site and certificate. Only
          proxies listing it in their `domains` are served here. Forwarded from
          `host.services.native.caddy.secondaryDomain`; empty disables it.
        '';
      };

      proxies = lib.mkOption {
        type = listOf (submodule { imports = [ (import ../../../types/caddy_proxy.nix { inherit lib; }) ]; });
        default = [ ];
        example = [{ subdomain = "vault"; port = 8222; }];
        description = ''
          Backends to front. Filled in by apps' own `subdomain` options and by
          `host.services.native.caddy.proxies` in build-time args.
        '';
      };

      sopsFile = lib.mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "./secrets.enc.yaml";
        description = ''
          sops file holding the Cloudflare API token. Forwarded from `host.sopsFile`.
        '';
      };

      cloudflareApiTokenSecretRef = lib.mkOption {
        type = types.str;
        default = "caddy/cloudflareApiToken";
        description = ''
          Key within `sopsFile` holding the Cloudflare API token (Zone:DNS:Edit + Zone:Zone:Read).
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
      { assertion = cfg.primaryDomain != "";
        message = "services.native.caddy requires 'primaryDomain', normally forwarded from 'host.network.domain'";
      }
      { assertion = cfg.secondaryDomain != cfg.primaryDomain;
        message = "services.native.caddy: secondaryDomain must differ from primaryDomain";
      }
      { assertion = unknownDomains == [ ];
        message = "services.native.caddy: proxy domains that are neither primaryDomain nor secondaryDomain: ${lib.concatStringsSep ", " unknownDomains}";
      }
      { assertion = duplicateSubdomains == [ ];
        message = "services.native.caddy: host(s) claimed by more than one proxy: ${lib.concatStringsSep ", " duplicateSubdomains}";
      }
    ];

    # Token as an EnvironmentFile. Restart, not reload: env vars are only read at start.
    secret.templates."caddy-cloudflare" = {
      filemode = "0400";
      content = ''
        CF_API_TOKEN=${config.secret.ref.${cfg.cloudflareApiTokenSecretRef}}
      '';
      secrets.${cfg.cloudflareApiTokenSecretRef}.sopsFile = cfg.sopsFile;
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
      #   assume a hostname that selects the wildcard cert; routing still uses the Host header
      globalConfig = ''
        auto_https disable_redirects
        default_sni fallback.${cfg.primaryDomain}
      '' + lib.optionalString (cfg.trustedProxies != [ ]) ''
        servers {
          trusted_proxies static ${lib.concatStringsSep " " cfg.trustedProxies}
          # Right-to-left: the client IP is the first untrusted hop, not a client-supplied leftmost
          trusted_proxies_strict
        }
      '';

      environmentFile = config.secret.templates."caddy-cloudflare".path;

      virtualHosts = lib.optionalAttrs (wildcardProxies != [ ])
        (lib.listToAttrs (map wildcardSite domains));
    };

    # UDP for HTTP/3
    networking.firewall.allowedTCPPorts = lib.optional (wildcardProxies != [ ]) 443;
    networking.firewall.allowedUDPPorts = lib.optional (wildcardProxies != [ ]) 443;

    # Fail the build if the generated Caddyfile doesn't validate. The dummy token is never used, and
    # the log dir is swapped for $TMPDIR since `validate` opens the log files.
    system.checks = [
      (pkgs.runCommand "caddy-config-validate" { } ''
        export HOME=$TMPDIR XDG_DATA_HOME=$TMPDIR XDG_CONFIG_HOME=$TMPDIR
        export CF_API_TOKEN=0000000000000000000000000000000000000000
        sed 's|${config.services.caddy.logDir}|'"$TMPDIR"'|g' ${config.services.caddy.configFile} > Caddyfile
        ${lib.getExe config.services.caddy.package} validate --config Caddyfile --adapter caddyfile
        touch $out
      '')
    ];
  };
}
