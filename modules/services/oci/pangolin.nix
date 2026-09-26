# Pangolin configuration
# - https://docs.pangolin.net/
# - https://github.com/fosrl/pangolin
#
# ### Description
# Deploys Pangolin's own four-container stack (pangolin, gerbil, traefik, crowdsec) via
# `podman-compose`, since Pangolin isn't in nixpkgs and its inter-container wiring
# (`network_mode: service:gerbil`, health-conditioned `depends_on`) is already hardened we'll use the
# upstream configuration via compose.

# ### Documented exceptions from upstream's raw installer template
# - pinned explicit image versions
# - `crowdsec`'s Prometheus port (6060) is not published - nothing in this stack needs it externally,
# - `pangolin`'s memory limit tightened to `1g` (from upstream's `2g` default) - a 2GB-class VPS
#   doesn't have headroom for one of four containers to claim a limit at/above total system RAM.
# - IPv6 left off (`enable_ipv6` omitted) - this fleet disables IPv6 everywhere
# - DNS-01 (Cloudflare) + wildcard certs from the start, not upstream's HTTP-01 default - port 80 is
#   never published at all, sidestepping the "ufw/nftables can't actually close it once Docker/podman
#   already published it" gotcha entirely rather than closing it after the fact.
# - CrowdSec `COLLECTIONS` matches upstream's own `--crowdsec` installer default
#   (`traefik`/`appsec-virtual-patching`/`appsec-generic-rules`) plus `http-cve` - a maintained,
#   HTTP-CVE-exploitation-detection collection recommended for any internet-facing deployment.
#   `base-http-scenarios` is deliberately not listed separately - it's already a dependency of the
#   `traefik` collection itself, so adding it again is a no-op.
#
# ### Secrets
# `secrets` must point at a `secrets.enc.yaml` holding:
# - `pangolin/serverSecret`  - session/token signing key (`openssl rand -base64 32`)
# - `pangolin/cloudflareApiToken` - scoped Cloudflare API token (Zone:DNS:Edit + Zone:Zone:Read) for
#   the DNS-01 challenge
# - `crowdsec` <-> Traefik bouncer key
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.oci.pangolin;
  dataDir = "/var/lib/${cfg.name}";

  composeText = ''
    name: ${cfg.name}
    services:
      pangolin:
        image: docker.io/fosrl/pangolin:${cfg.pangolinTag}
        container_name: ${cfg.name}
        restart: unless-stopped
        deploy:
          resources:
            limits:
              memory: ${cfg.memoryLimit}
            reservations:
              memory: ${cfg.memoryReservation}
        volumes:
          - ./config:/app/config
        healthcheck:
          test: ["CMD", "curl", "-f", "http://localhost:3001/api/v1/"]
          interval: "10s"
          timeout: "10s"
          retries: 15

      gerbil:
        image: docker.io/fosrl/gerbil:${cfg.gerbilTag}
        container_name: gerbil
        restart: unless-stopped
        depends_on:
          pangolin:
            condition: service_healthy
        command:
          - --reachableAt=http://gerbil:3004
          - --generateAndSaveKeyTo=/var/config/key
          - --remoteConfig=http://pangolin:3001/api/v1/
        volumes:
          - ./config/:/var/config
        cap_add:
          - NET_ADMIN
          - SYS_MODULE
        ports:
          - 51820:51820/udp
          - 21820:21820/udp
          - 443:443
          - 443:443/udp

      traefik:
        image: docker.io/traefik:${cfg.traefikTag}
        container_name: traefik
        restart: unless-stopped
        network_mode: service:gerbil
        depends_on:
          pangolin:
            condition: service_healthy
          crowdsec:
            condition: service_healthy
        env_file:
          - .env
        command:
          - --configFile=/etc/traefik/traefik_config.yml
        volumes:
          - ./config/traefik:/etc/traefik:ro
          - ./config/letsencrypt:/letsencrypt
          - ./config/traefik/logs:/var/log/traefik

      crowdsec:
        image: docker.io/crowdsecurity/crowdsec:${cfg.crowdsecTag}
        container_name: crowdsec
        restart: unless-stopped
        environment:
          GID: "1000"
          COLLECTIONS: ${lib.concatStringsSep " " cfg.crowdsecCollections}
          ENROLL_INSTANCE_NAME: "${cfg.name}-crowdsec"
          PARSERS: crowdsecurity/whitelists
          ENROLL_TAGS: docker
        healthcheck:
          test: ["CMD", "cscli", "lapi", "status"]
          interval: "10s"
          timeout: "5s"
          retries: 3
          start_period: "30s"
        labels:
          - "traefik.enable=false"
        volumes:
          - ./config/crowdsec:/etc/crowdsec
          - ./config/crowdsec/db:/var/lib/crowdsec/data
          - ./config/traefik/logs:/var/log/traefik

    networks:
      default:
        driver: bridge
        name: ${cfg.name}_frontend
  '';

  traefikConfigText = ''
    api:
      insecure: true
      dashboard: true

    providers:
      http:
        endpoint: "http://pangolin:3001/api/v1/traefik-config"
        pollInterval: "5s"
      file:
        # Directory (not filename) mode is required for the geo-allowlist below to hot-reload -
        # Traefik's single-file mode never watches for changes, only directory mode does. This
        # also means dynamic_config.yml itself now picks up edits live, though nothing here
        # currently relies on that (the crowdsec-bouncer key patch below still explicitly restarts
        # traefik rather than assuming the reload landed in time).
        directory: "/etc/traefik/dynamic"
        watch: true

    experimental:
      plugins:
        badger:
          moduleName: "github.com/fosrl/badger"
          version: "${cfg.badgerPluginVersion}"
        crowdsec:
          moduleName: "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin"
          version: "${cfg.crowdsecPluginVersion}"

    log:
      level: "INFO"
      format: "json"
      maxSize: 100
      maxBackups: 3
      maxAge: 3
      compress: true

    accessLog:
      filePath: "/var/log/traefik/access.log"
      format: json
      filters:
        statusCodes:
          - "200-299"
          - "400-499"
          - "500-599"
        retryAttempts: true
        minDuration: "100ms"
      bufferingSize: 100
      fields:
        defaultMode: drop
        names:
          ClientAddr: keep
          ClientHost: keep
          RequestMethod: keep
          RequestPath: keep
          RequestProtocol: keep
          DownstreamStatus: keep
          DownstreamContentSize: keep
          Duration: keep
          ServiceName: keep
          StartUTC: keep
          TLSVersion: keep
          TLSCipher: keep
          RetryAttempts: keep
        headers:
          defaultMode: drop
          names:
            User-Agent: keep
            X-Real-Ip: keep
            X-Forwarded-For: keep
            X-Forwarded-Proto: keep
            Content-Type: keep
            Authorization: redact
            Cookie: redact

    certificatesResolvers:
      letsencrypt:
        acme:
          dnsChallenge:
            provider: cloudflare
            propagation:
              delayBeforeChecks: "30s"
          email: "${cfg.acmeEmail}"
          storage: "/letsencrypt/acme.json"
          caServer: "https://acme-v02.api.letsencrypt.org/directory"

    entryPoints:
      web:
        address: ":80"
      websecure:
        address: ":443"
        transport:
          respondingTimeouts:
            readTimeout: "30m"
        http3:
          advertisedPort: 443
        http:
          tls:
            certResolver: "letsencrypt"
          middlewares:
            # us-allowlist runs first - a short-circuiting nftables-style set lookup that rejects
            # non-US traffic before crowdsec@file ever makes its synchronous LAPI/AppSec round-trip
            # (host-level geo-blocking never covered this path at all - see the "Traefik geoblock"
            # comment on the geoblockAllowList option below for why).
            - us-allowlist@file
            - crowdsec@file
          encodedCharacters:
            allowEncodedSlash: true
            allowEncodedQuestionMark: true

    serversTransport:
      insecureSkipVerify: true

    ping:
      entryPoint: "web"
  '';

  # Wildcard `domains:` override applied to all three websecure routers that match the dashboard
  # host (not just next-router) - see the tech-doc's "Enable Wildcard Certificates" section for why
  # all three need it independently, or Traefik keeps issuing/preferring a separate exact-match cert
  # for the dashboard domain alongside the wildcard.
  # Built from explicitly-indented lines rather than a `''...''` literal: Nix's indented-string
  # syntax strips the MINIMUM common leading whitespace across every line, independently of
  # whatever column the `${wildcardTls}` placeholder sits at in dynamicConfigText - so the
  # interpolated value previously always landed flush-left (column 0) regardless of context,
  # breaking the YAML nesting under each router's `rule:`/`service:`/etc siblings. Confirmed live:
  # Traefik's file provider failed to parse the ENTIRE dynamic_config.yml as a result, meaning
  # next-router/api-router/ws-router (and therefore every middleware and backend route) never
  # actually loaded - only surfaced now that the tmpfiles r+C+ fix above lets this file refresh at
  # all (hosts/vm-vps1 testing, 2026-09-22). These lines carry their real absolute column position
  # baked in, so string concatenation reproduces it exactly regardless of call-site indentation.
  wildcardTls = lib.concatStringsSep "\n" [
    "      tls:"
    "        certResolver: letsencrypt"
    "        domains:"
    "          - main: \"${cfg.baseDomain}\""
    "            sans:"
    "              - \"*.${cfg.baseDomain}\""
  ];

  dynamicConfigText = ''
    http:
      middlewares:
        badger:
          plugin:
            badger:
              disableForwardAuth: true
        redirect-to-https:
          redirectScheme:
            scheme: https
        default-whitelist:
          ipWhiteList:
            sourceRange:
              - "10.0.0.0/8"
              - "192.168.0.0/16"
              - "172.16.0.0/12"
        security-headers:
          headers:
            customResponseHeaders:
              Server: ""
              X-Powered-By: ""
              X-Forwarded-Proto: "https"
            sslProxyHeaders:
              X-Forwarded-Proto: "https"
            hostsProxyHeaders:
              - "X-Forwarded-Host"
            contentTypeNosniff: true
            customFrameOptionsValue: "SAMEORIGIN"
            referrerPolicy: "strict-origin-when-cross-origin"
            forceSTSHeader: true
            stsIncludeSubdomains: true
            stsSeconds: 63072000
            stsPreload: true
        crowdsec:
          plugin:
            crowdsec:
              enabled: true
              logLevel: INFO
              updateIntervalSeconds: 15
              updateMaxFailure: 0
              defaultDecisionSeconds: 15
              httpTimeoutSeconds: 10
              crowdsecMode: live
              crowdsecAppsecEnabled: true
              crowdsecAppsecHost: crowdsec:7422
              crowdsecAppsecFailureBlock: true
              crowdsecAppsecUnreachableBlock: true
              crowdsecAppsecBodyLimit: 10485760
              crowdsecLapiKey: "PUT_YOUR_BOUNCER_KEY_HERE_OR_IT_WILL_NOT_WORK"
              crowdsecLapiHost: crowdsec:8080
              crowdsecLapiScheme: http
              forwardedHeadersTrustedIPs:
                - "0.0.0.0/0"
              clientTrustedIPs:
                - "10.0.0.0/8"
                - "172.16.0.0/12"
                - "192.168.0.0/16"
                - "100.89.137.0/20" # Gerbil's default site-tunnel CGNAT range - keep in sync with any override

      routers:
        main-app-router-redirect:
          rule: "Host(`${cfg.dashboardDomain}`)"
          service: next-service
          entryPoints:
            - web
          middlewares:
            - redirect-to-https
            - badger

        next-router:
          rule: "Host(`${cfg.dashboardDomain}`) && !PathPrefix(`/api/v1`)"
          service: next-service
          entryPoints:
            - websecure
          middlewares:
            - security-headers
            - badger
    ${wildcardTls}

        api-router:
          rule: "Host(`${cfg.dashboardDomain}`) && PathPrefix(`/api/v1`)"
          service: api-service
          entryPoints:
            - websecure
          middlewares:
            - security-headers
            - badger
    ${wildcardTls}

        ws-router:
          rule: "Host(`${cfg.dashboardDomain}`)"
          service: api-service
          entryPoints:
            - websecure
          middlewares:
            - security-headers
            - badger
    ${wildcardTls}

      services:
        next-service:
          loadBalancer:
            servers:
              - url: "http://pangolin:3002"

        api-service:
          loadBalancer:
            servers:
              - url: "http://pangolin:3000"

    tcp:
      serversTransports:
        pp-transport-v1:
          proxyProtocol:
            version: 1
        pp-transport-v2:
          proxyProtocol:
            version: 2
  '';

  crowdsecAcquisTraefikText = ''
    poll_without_inotify: false
    filenames:
      - /var/log/traefik/*.log
    labels:
      type: traefik
  '';

  crowdsecAcquisAppsecText = ''
    listen_addr: 0.0.0.0:7422
    appsec_config: crowdsecurity/appsec-default
    name: myAppSecComponent
    source: appsec
    labels:
      type: appsec
  '';

  crowdsecProfilesText = ''
    name: captcha_remediation
    filters:
      - Alert.Remediation == true && Alert.GetScope() == "Ip" && Alert.GetScenario() contains "http"
    decisions:
      - type: captcha
        duration: 4h
    on_success: break

    ---
    name: default_ip_remediation
    filters:
     - Alert.Remediation == true && Alert.GetScope() == "Ip"
    decisions:
     - type: ban
       duration: 4h
    on_success: break

    ---
    name: default_range_remediation
    filters:
     - Alert.Remediation == true && Alert.GetScope() == "Range"
    decisions:
     - type: ban
       duration: 4h
    on_success: break
  '';

  # Traefik geoblock - closes a gap host-level geo-blocking never covered: `devices.network.harden`'s
  # geoblock-chain only hooks the host's own `input` chain, so it never sees traffic DNAT'd into a
  # container (netfilter's routing decision runs after DNAT rewrites the destination to the
  # container's private IP, sending it through `forward` instead) - meaning Traefik's published 443
  # had zero country-based filtering regardless of the host-level geoblock. Same upstream CIDR
  # source and same "bake the allowlist in, refresh the fetched list independently" shape as
  # devices.network.harden's own geoblock, just expressed as a Traefik dynamic-config file instead
  # of an nftables set, since nftables can't see into forwarded container traffic at all.
  usCidrUrl = "https://raw.githubusercontent.com/ipverse/country-ip-blocks/master/country/us/ipv4-aggregated.txt";

  # Static half of the geo-allowlist file: the header plus geoblockAllowList's entries, baked in so
  # the file is well-formed and non-empty from the very first activation (zero network dependency -
  # mirrors devices.network.harden.geoblockAllowList's own "closes the boot to first-refresh gap"
  # reasoning). The refresh service below appends the fetched US CIDRs to this same header.
  #
  # The leading placeholder entry (RFC 5737 TEST-NET-1, never a real client address) is not
  # optional even when geoblockAllowList is empty: Traefik's file provider rejects an ipAllowList
  # middleware whose sourceRange resolves to an empty list as "cannot be a standalone element" -
  # and rejects the ENTIRE dynamic-config directory when that happens, not just this middleware,
  # taking down every router/service Pangolin/Traefik serve until the next successful reload
  # (confirmed live: this exact empty-sourceRange state during the ~2min boot-to-first-refresh
  # window blanked the whole stack - hosts/vm-vps1 testing, 2026-09-22).
  # Built from explicit lines (not a `''...''` literal) so its indentation is unambiguous and
  # matches the 12-space list-item convention the geoblock-refresh script's own `sed` output and
  # the appended geoblockAllowList entries below both use - mixing an auto-dedented block with
  # separately-concatenated literal-indent lines is exactly the mismatch that broke wildcardTls.
  geoAllowlistHeaderText = lib.concatStringsSep "\n" ([
    "http:"
    "  middlewares:"
    "    us-allowlist:"
    "      ipAllowList:"
    "        sourceRange:"
    "            - 192.0.2.1"
  ] ++ map (ip: "            - ${ip}") cfg.geoblockAllowList) + "\n";

  # Forces the systemd unit definition itself to change whenever any rendered config changes -
  # otherwise a `nixos-rebuild switch` that only updates a symlink target doesn't bump the unit's
  # own hash, so NixOS never restarts it and podman-compose never re-applies the new config.
  configRev = builtins.hashString "sha256" (
    composeText + traefikConfigText + dynamicConfigText + crowdsecAcquisTraefikText
    + crowdsecAcquisAppsecText + crowdsecProfilesText + geoAllowlistHeaderText
  );
in
{
  options.services.oci.pangolin = {
    enable = lib.mkEnableOption "Deploy Pangolin (pangolin+gerbil+traefik+crowdsec) via podman-compose";

    name = lib.mkOption {
      description = lib.mdDoc "Compose project / container-name prefix";
      type = types.str;
      default = "pangolin";
    };

    pangolinTag = lib.mkOption {
      description = lib.mdDoc "fosrl/pangolin image tag - check github.com/fosrl/pangolin/releases for current";
      type = types.str;
      example = "ee-1.21.1";
    };

    gerbilTag = lib.mkOption {
      description = lib.mdDoc "fosrl/gerbil image tag - check github.com/fosrl/gerbil/releases for current";
      type = types.str;
      example = "1.5.1";
    };

    traefikTag = lib.mkOption {
      description = lib.mdDoc "traefik image tag - check Traefik's release page for current";
      type = types.str;
      example = "v3.7";
    };

    crowdsecTag = lib.mkOption {
      description = lib.mdDoc ''
        crowdsecurity/crowdsec image tag - pinned deliberately (upstream's own `--crowdsec`
        installer template floats `:latest`), see the module-level "Documented exceptions" note.
        Check github.com/crowdsecurity/crowdsec/releases for current.
      '';
      type = types.str;
      example = "v1.7.8";
    };

    badgerPluginVersion = lib.mkOption {
      description = lib.mdDoc "fosrl/badger Traefik plugin version - check github.com/fosrl/badger/releases";
      type = types.str;
      example = "v1.5.0";
    };

    crowdsecPluginVersion = lib.mkOption {
      description = lib.mdDoc ''
        maxlerebourg/crowdsec-bouncer-traefik-plugin version - check that repo's releases
      '';
      type = types.str;
      example = "v1.4.4";
    };

    crowdsecCollections = lib.mkOption {
      description = lib.mdDoc "CrowdSec hub collections installed into the Traefik-facing engine";
      type = types.listOf types.str;
      default = [
        "crowdsecurity/traefik"
        "crowdsecurity/http-cve"
        "crowdsecurity/appsec-virtual-patching"
        "crowdsecurity/appsec-generic-rules"
      ];
    };

    baseDomain = lib.mkOption {
      description = lib.mdDoc ''
        Base domain resources/wildcard cert are issued under, e.g. example.com. Nullable so
        `modules/default.nix` can unconditionally forward `machine.services.oci.pangolin.baseDomain`
        (host args) here without an existence check - see the `enable`-gated assertion below for
        the actual requirement.
      '';
      type = types.nullOr types.str;
      default = null;
    };

    dashboardDomain = lib.mkOption {
      description = lib.mdDoc "Pangolin dashboard hostname";
      type = types.str;
      default = "pangolin.${cfg.baseDomain}";
    };

    acmeEmail = lib.mkOption {
      description = lib.mdDoc ''
        Contact email for Let's Encrypt ACME registration. Nullable so `modules/default.nix` can
        unconditionally forward `host.services.oci.pangolin.acmeEmail` (host args) here without
        an existence check - see the `enable`-gated assertion below for the actual requirement.
      '';
      type = types.nullOr types.str;
      default = null;
    };

    memoryLimit = lib.mkOption {
      description = lib.mdDoc "Soft memory ceiling for the pangolin container - see Documented exceptions";
      type = types.str;
      default = "1g";
    };

    memoryReservation = lib.mkOption {
      description = lib.mdDoc "Memory reservation for the pangolin container";
      type = types.str;
      default = "512m";
    };

    geoblockAllowList = lib.mkOption {
      description = lib.mdDoc ''
        CIDRs/IPs that always bypass Traefik's US geo-allowlist regardless of country, mirroring
        `devices.network.harden.geoblockAllowList`'s purpose - a safety valve against a
        self-inflicted lockout if the upstream geoIP data is ever wrong, or the admin travels/tunnels
        through a non-US VPN exit. Baked directly into the allowlist file's initial contents (zero
        network dependency at boot) and re-applied on every subsequent daily refresh alongside the
        fetched US list.
      '';
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "203.0.113.7" "198.51.100.0/24" ];
    };

    sopsFile = lib.mkOption {
      type = types.path;
      example = "./secrets.enc.yaml";
      description = lib.mdDoc ''
        Path to the sops-encrypted file holding `pangolin/serverSecret` and
        `pangolin/cloudflareApiToken` - see the module-level Secrets note.
      '';
    };

    disableUserCreateOrg = lib.mkOption {
      description = lib.mdDoc "Whether to prevent non-admin users from creating their own organization";
      type = types.bool;
      default = true;
    };

    rateLimitWindowMinutes = lib.mkOption {
      description = lib.mdDoc "Global rate-limit window, in minutes";
      type = types.int;
      default = 1;
    };

    rateLimitMaxRequests = lib.mkOption {
      description = lib.mdDoc "Global rate-limit max requests per window";
      type = types.int;
      default = 100;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = cfg.baseDomain != null && cfg.baseDomain != ""; message = "services.oci.pangolin requires 'baseDomain', normally forwarded from 'host.network.domain'"; }
      { assertion = cfg.acmeEmail != null; message = "services.oci.pangolin requires 'acmeEmail'"; }
    ];

    virtualization.podman.enable = true;

    # Same caveat as every other services.oci.* module publishing container ports: podman's own
    # NAT/forward rules reach these regardless of networking.firewall - these entries are
    # documentation/consistency, not the actual gate. Verify a CrowdSec ban (native
    # crowdsec-firewall-bouncer or this stack's own docker-scoped engine, two separate LAPIs) still
    # intercepts traffic to these ports before relying on either as the real enforcement point.
    networking.firewall.allowedTCPPorts = [ 443 ];
    networking.firewall.allowedUDPPorts = [ 443 51820 21820 ];

    # Non-secret config - rendered directly into the Nix store and symlinked into place, so a
    # nixos-rebuild switch always reflects the current module source. Runtime-writable state
    # (acme.json, crowdsec's db, access logs, Pangolin's own db/, mmdb files) lives in plain
    # directories created below, never symlinked.
    systemd.tmpfiles.rules = [
      "d ${dataDir} 0750 root root -"
      "d ${dataDir}/config 0750 root root -"
      "d ${dataDir}/config/db 0750 root root -"
      "d ${dataDir}/config/logs 0750 root root -"
      "d ${dataDir}/config/letsencrypt 0700 root root -"
      "d ${dataDir}/config/traefik 0750 root root -"
      "d ${dataDir}/config/traefik/dynamic 0750 root root -"
      "d ${dataDir}/config/traefik/logs 0750 root root -"
      "d ${dataDir}/config/crowdsec 0750 root root -"
      "d ${dataDir}/config/crowdsec/db 0750 root root -"
      "d ${dataDir}/config/crowdsec/acquis.d 0750 root root -"
      "d ${dataDir}/state 0700 root root -"

      "L+ ${dataDir}/docker-compose.yml - - - - ${pkgs.writeText "${cfg.name}-compose.yml" composeText}"
      # Configs below land under dataDir/config, which gets bind-mounted wholesale into one
      # container or another (see the `volumes:` entries above) - a container's mount namespace
      # can't resolve a symlink pointing at a host-only path like /nix/store or
      # sops-nix's /run/secrets-rendered, so these must be real copies (C+), not symlinks (L+),
      # unlike docker-compose.yml/.env above which podman-compose itself reads from the host.
      #
      # Each C+ is preceded by an `r` (remove) of the same path. Despite the module's original
      # claim that C+ "always reflects the current module source", systemd-tmpfiles.d(5) is
      # explicit that C/C+ only copies "if the destination files or directories do not exist yet"
      # - the `+` suffix only changes whether an *existing non-empty directory* gets descended
      # into, it has no effect on an existing regular file at all. Confirmed live: every one of
      # these files was silently frozen at its very first-ever rendered content, un-refreshed by
      # any subsequent `nixos-rebuild switch` (found while verifying the Traefik geo-allowlist
      # feature below never took effect despite a clean build - hosts/vm-vps1 testing,
      # 2026-09-22). `r` doesn't error if the path is already missing, so this is safe on a
      # first-ever activation too.
      "r ${dataDir}/config/traefik/traefik_config.yml"
      "C+ ${dataDir}/config/traefik/traefik_config.yml - - - - ${pkgs.writeText "${cfg.name}-traefik-config.yml" traefikConfigText}"
      "r ${dataDir}/config/traefik/dynamic/dynamic_config.yml"
      "C+ ${dataDir}/config/traefik/dynamic/dynamic_config.yml - - - - ${pkgs.writeText "${cfg.name}-dynamic-config.yml" dynamicConfigText}"
      # Baseline only (geoblockAllowList entries, no fetched US CIDRs yet) - re-applied on every
      # switch, same as devices.network.harden's nftables geoblock skeleton. The geoblock-refresh
      # service below overwrites this same path with the full fetched list, independently of any
      # nixos-rebuild switch, until the next switch resets it back to this baseline.
      "r ${dataDir}/config/traefik/dynamic/geo-allowlist.yml"
      "C+ ${dataDir}/config/traefik/dynamic/geo-allowlist.yml - - - - ${pkgs.writeText "${cfg.name}-geo-allowlist-initial.yml" geoAllowlistHeaderText}"
      "r ${dataDir}/config/crowdsec/acquis.d/traefik.yaml"
      "C+ ${dataDir}/config/crowdsec/acquis.d/traefik.yaml - - - - ${pkgs.writeText "${cfg.name}-crowdsec-acquis-traefik.yaml" crowdsecAcquisTraefikText}"
      "r ${dataDir}/config/crowdsec/acquis.d/appsec.yaml"
      "C+ ${dataDir}/config/crowdsec/acquis.d/appsec.yaml - - - - ${pkgs.writeText "${cfg.name}-crowdsec-acquis-appsec.yaml" crowdsecAcquisAppsecText}"
      "r ${dataDir}/config/crowdsec/profiles.yaml"
      "C+ ${dataDir}/config/crowdsec/profiles.yaml - - - - ${pkgs.writeText "${cfg.name}-crowdsec-profiles.yaml" crowdsecProfilesText}"

      # Secret-bearing config - targets rendered by the secret.templates entries below. Same
      # never-refreshes bug applies here too - without the `r`, rotating
      # pangolin/serverSecret or pangolin/cloudflareApiToken would silently never reach the
      # container after the first-ever deploy.
      "r ${dataDir}/config/config.yml"
      "C+ ${dataDir}/config/config.yml - - - - ${config.secret.templates."${cfg.name}-config".path}"
      "L+ ${dataDir}/.env - - - - ${config.secret.templates."${cfg.name}-env".path}"
    ];

    # Secret-bearing config, rendered at activation to sops-nix's default path and symlinked in -
    # never lands in the Nix store or git, unlike the plain configs above.
    secret.templates."${cfg.name}-config" = {
      filemode = "0400";
      content = ''
        gerbil:
            start_port: 51820
            base_endpoint: "${cfg.dashboardDomain}"

        app:
            dashboard_url: "https://${cfg.dashboardDomain}"
            log_level: "info"
            telemetry:
                anonymous_usage: true
            save_logs: true
            log_failed_attempts: true

        domains:
            domain1:
                base_domain: "${cfg.baseDomain}"
                prefer_wildcard_cert: true
                cert_resolver: "letsencrypt"

        server:
            secret: "${config.secret.ref."${cfg.name}/serverSecret"}"
            maxmind_db_path: "./config/GeoLite2-Country.mmdb"
            maxmind_asn_path: "./config/GeoLite2-ASN.mmdb"
            cors:
                origins: ["https://${cfg.dashboardDomain}"]
                methods: ["GET", "POST", "PUT", "DELETE", "PATCH"]
                allowed_headers: ["X-CSRF-Token", "Content-Type"]
                credentials: false
            trust_proxy: 1

        rate_limits:
            global:
                window_minutes: ${toString cfg.rateLimitWindowMinutes}
                max_requests: ${toString cfg.rateLimitMaxRequests}

        traefik:
            additional_middlewares:
                - "security-headers@file"

        flags:
            require_email_verification: false
            disable_signup_without_invite: true
            disable_user_create_org: ${lib.boolToString cfg.disableUserCreateOrg}
            allow_raw_resources: true
      '';
      secrets."${cfg.name}/serverSecret".sopsFile = cfg.sopsFile;
      # configRev below only hashes the *plaintext* configs, so a rotated serverSecret changes
      # this rendered file without changing the stack unit's own definition - nothing would
      # restart it and the containers would keep running against the old value
      restartUnits = [ "${cfg.name}-stack.service" ];
    };

    secret.templates."${cfg.name}-env" = {
      filemode = "0400";
      content = ''
        CF_DNS_API_TOKEN=${config.secret.ref."${cfg.name}/cloudflareApiToken"}
      '';
      secrets."${cfg.name}/cloudflareApiToken".sopsFile = cfg.sopsFile;
      # Same configRev gap as the config template above - traefik reads CF_DNS_API_TOKEN from
      # .env at container start only
      restartUnits = [ "${cfg.name}-stack.service" ];
    };

    # Periodic MaxMind GeoLite2 refresh - same GitHub mirror the upstream installer pulls from (no
    # MaxMind account/license key needed). These are point-in-time snapshots (IP-to-country/ASN
    # mappings drift as blocks get reallocated), hence the weekly timer rather than a one-shot fetch.
    systemd.services."${cfg.name}-geolite-refresh" = {
      description = "Refresh Pangolin's MaxMind GeoLite2 databases";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = [ pkgs.curl pkgs.gnutar pkgs.gzip pkgs.coreutils ];
      serviceConfig.Type = "oneshot";
      script = ''
        set -euo pipefail
        tmp=$(mktemp -d)
        trap 'rm -rf "$tmp"' EXIT
        cd "$tmp"
        curl -fsSL -o country.tar.gz https://github.com/GitSquared/node-geolite2-redist/raw/refs/heads/master/redist/GeoLite2-Country.tar.gz
        curl -fsSL -o asn.tar.gz https://github.com/GitSquared/node-geolite2-redist/raw/refs/heads/master/redist/GeoLite2-ASN.tar.gz
        tar -xzf country.tar.gz
        tar -xzf asn.tar.gz
        install -m 0644 GeoLite2-Country_*/GeoLite2-Country.mmdb ${dataDir}/config/GeoLite2-Country.mmdb
        install -m 0644 GeoLite2-ASN_*/GeoLite2-ASN.mmdb ${dataDir}/config/GeoLite2-ASN.mmdb
      '';
    };
    systemd.timers."${cfg.name}-geolite-refresh" = {
      wantedBy = [ "timers.target" ];
      timerConfig = { OnCalendar = "weekly"; Persistent = true; RandomizedDelaySec = "1h"; };
    };

    # Refresh of Traefik's us-allowlist middleware - same CIDR source and "fail safe to yesterday's
    # list" reasoning as devices.network.harden's own geoblock-refresh (curl --fail + set -e aborts
    # before install ever runs on a bad fetch, leaving the previous file untouched), just targeting
    # a Traefik dynamic-config file instead of an nftables set. See geoAllowlistHeaderText's comment
    # above for why this exists as a separate mechanism from the host-level geoblock.
    systemd.services."${cfg.name}-geoblock-refresh" = {
      description = "Refresh Traefik's US IPv4 allowlist middleware for the ${cfg.name} stack";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = [ pkgs.curl pkgs.gnugrep pkgs.gnused pkgs.coreutils ];
      serviceConfig.Type = "oneshot";
      script = ''
        set -euo pipefail
        tmp=$(mktemp)
        trap 'rm -f "$tmp"' EXIT
        cat ${pkgs.writeText "${cfg.name}-geo-allowlist-header.yml" geoAllowlistHeaderText} > "$tmp"
        curl --fail --silent --show-error "${usCidrUrl}" \
          | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$' \
          | sed 's/^/            - /' >> "$tmp"
        install -m 0644 "$tmp" ${dataDir}/config/traefik/dynamic/geo-allowlist.yml
      '';
    };
    systemd.timers."${cfg.name}-geoblock-refresh" = {
      description = "Daily refresh of the ${cfg.name} stack's Traefik US IPv4 allowlist";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";       # minimize the geoblockAllowList-only window after boot
        OnUnitActiveSec = "1d";   # matches ipverse/country-ip-blocks' own daily CI cadence
        RandomizedDelaySec = 300;
        Persistent = true;
      };
    };

    # Traefik's own access log (config/traefik/logs/access.log) grows unbounded otherwise - nothing
    # in the compose stack rotates it, same as upstream's plain install.
    services.logrotate.settings."${cfg.name}-traefik" = {
      files = [ "${dataDir}/config/traefik/logs/access.log" ];
      frequency = "daily";
      rotate = 7;
      compress = true;
      delaycompress = true;
      missingok = true;
      notifempty = true;
    };

    # The compose stack itself - a oneshot "up -d"/"down" pair rather than a long-running
    # ExecStart, matching how podman-compose is meant to be driven from systemd (podman itself is
    # daemonless; `up -d` backgrounds each container under podman, not under this unit).
    # environment.CONFIG_REV forces this unit's own definition to change whenever any rendered
    # config changes, so NixOS actually restarts it on switch instead of leaving a stale symlink
    # target in place - see configRev's comment above.
    systemd.services."${cfg.name}-stack" = {
      description = "Pangolin stack (pangolin/gerbil/traefik/crowdsec) via podman-compose";
      # Must wait on geolite-refresh finishing (not just being wanted) - without this ordering,
      # a fresh VM starts the compose stack before the GeoLite2 mmdb files ever exist (the timer's
      # OnCalendar=weekly won't fire again for up to a week), and pangolin crashes on every start
      # with ENOENT on ./config/GeoLite2-Country.mmdb - confirmed live as a 1700+ restart crash
      # loop whose constant veth teardown/recreate also broke crowdsec's DNS lookups on the same
      # bridge (hosts/vm-vps1 testing, 2026-09-21).
      #
      # Same ordering applied to geoblock-refresh, for a different reason: every switch that
      # changes any rendered config forces this unit to restart (see CONFIG_REV below), and the
      # tmpfiles `r`+`C+` pair for geo-allowlist.yml (see its comment above) resets that file to
      # its bare baseline - placeholder + geoblockAllowList only, no fetched US CIDRs - on every
      # single switch, not just first boot. The geoblock-refresh timer's OnBootSec only fires
      # after an actual reboot and OnUnitActiveSec=1d only re-fires a day after its last run, so
      # without this ordering a plain `nixos-rebuild switch` (no reboot) would silently drop
      # Traefik's us-allowlist middleware back to blocking all but the explicit allowlist entries
      # for up to 24h - confirmed live: switch at 03:07 wiped the file the 02:43 boot-time refresh
      # had already populated, with the timer not due again until the next day (hosts/vm-vps1
      # testing, 2026-09-22). Ordering the refresh to run (and finish, success or failure) before
      # the stack starts closes that gap on every switch, same as geolite-refresh above.
      after = [
        "network-online.target"
        "podman.service"
        "${cfg.name}-geolite-refresh.service"
        "${cfg.name}-geoblock-refresh.service"
      ];
      wants = [
        "network-online.target"
        "${cfg.name}-geolite-refresh.service"
        "${cfg.name}-geoblock-refresh.service"
      ];
      wantedBy = [ "multi-user.target" ];
      environment.CONFIG_REV = configRev;
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = dataDir;
        ExecStart = "${pkgs.podman-compose}/bin/podman-compose -f docker-compose.yml -p ${cfg.name} up -d";
        ExecStop = "${pkgs.podman-compose}/bin/podman-compose -f docker-compose.yml -p ${cfg.name} down";
        # podman-compose blocks on `podman wait --condition=healthy` for every service with a
        # healthcheck before returning - if a container never turns healthy (e.g. a crash loop),
        # that wait never returns, which without a bound here hangs this unit's start job (and
        # therefore the whole `nixos-rebuild switch` activation script, which starts units
        # synchronously) forever instead of failing after a bounded time. Confirmed live: a
        # missing-GeoLite2 crash loop hung activation for 18+ minutes with no timeout in place
        # (hosts/vm-vps1 testing, 2026-09-21).
        TimeoutStartSec = "5min";
      };
    };

    # CrowdSec splits detection (the crowdsec container) from enforcement (Traefik's crowdsec
    # bouncer plugin) - the plugin authenticates every LAPI call with a per-bouncer key that can
    # only be generated once crowdsec is actually running, so it can't be a sops-sourced secret
    # like server/cloudflare above. Idempotent and safe to re-run: skips registration once
    # state/bouncer-key exists, only restarts traefik if the deployed dynamic_config.yml doesn't
    # already carry the current key (e.g. after a fresh deploy, or the key file being reset).
    # Mirrors services.native.crowdsec.nix's own delete-then-recreate recovery pattern for the same
    # class of interrupted-registration hazard.
    systemd.services."${cfg.name}-crowdsec-bouncer" = {
      description = "Register Pangolin's Traefik CrowdSec bouncer and apply its LAPI key";
      after = [ "${cfg.name}-stack.service" ];
      requires = [ "${cfg.name}-stack.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.podman pkgs.gnused pkgs.coreutils ];
      serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
      script = ''
        set -euo pipefail
        dynCfg=${dataDir}/config/traefik/dynamic/dynamic_config.yml
        keyFile=${dataDir}/state/crowdsec-bouncer-key

        for i in $(seq 1 30); do
          podman exec crowdsec cscli lapi status >/dev/null 2>&1 && break
          sleep 2
        done

        if [ ! -s "$keyFile" ]; then
          podman exec crowdsec cscli bouncers delete --ignore-missing -- traefik-bouncer >/dev/null 2>&1 || true
          podman exec crowdsec cscli bouncers add traefik-bouncer -o raw > "$keyFile"
          chmod 0600 "$keyFile"
        fi

        key=$(cat "$keyFile")
        if ! grep -qF "$key" "$dynCfg"; then
          sed -i "s|crowdsecLapiKey: .*|crowdsecLapiKey: \"$key\"|" "$dynCfg"
          podman restart traefik
        fi
      '';
    };
  };
}
