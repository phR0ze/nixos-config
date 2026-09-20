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
# - CrowdSec `COLLECTIONS` matches `traefik`/`appsec-virtual-patching`/`appsec-generic-rules` -
#   exactly what was found already running on the validated reference deployment.
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
        filename: "/etc/traefik/dynamic_config.yml"

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
  wildcardTls = ''
        tls:
          certResolver: letsencrypt
          domains:
            - main: "${cfg.baseDomain}"
              sans:
                - "*.${cfg.baseDomain}"'';

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

  # Forces the systemd unit definition itself to change whenever any rendered config changes -
  # otherwise a `nixos-rebuild switch` that only updates a symlink target doesn't bump the unit's
  # own hash, so NixOS never restarts it and podman-compose never re-applies the new config.
  configRev = builtins.hashString "sha256" (
    composeText + traefikConfigText + dynamicConfigText + crowdsecAcquisTraefikText
    + crowdsecAcquisAppsecText + crowdsecProfilesText
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
        "crowdsecurity/appsec-virtual-patching"
        "crowdsecurity/appsec-generic-rules"
      ];
    };

    baseDomain = lib.mkOption {
      description = lib.mdDoc "Base domain resources/wildcard cert are issued under, e.g. example.com";
      type = types.str;
    };

    dashboardDomain = lib.mkOption {
      description = lib.mdDoc "Pangolin dashboard hostname";
      type = types.str;
      default = "pangolin.${cfg.baseDomain}";
    };

    acmeEmail = lib.mkOption {
      description = lib.mdDoc "Contact email for Let's Encrypt ACME registration";
      type = types.str;
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
      { assertion = cfg.baseDomain != ""; message = "services.oci.pangolin requires 'baseDomain'"; }
      { assertion = cfg.acmeEmail != ""; message = "services.oci.pangolin requires 'acmeEmail'"; }
    ];

    virtualisation.podman.enable = true;

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
      "d ${dataDir}/config/traefik/logs 0750 root root -"
      "d ${dataDir}/config/crowdsec 0750 root root -"
      "d ${dataDir}/config/crowdsec/db 0750 root root -"
      "d ${dataDir}/config/crowdsec/acquis.d 0750 root root -"
      "d ${dataDir}/state 0700 root root -"

      "L+ ${dataDir}/docker-compose.yml - - - - ${pkgs.writeText "${cfg.name}-compose.yml" composeText}"
      "L+ ${dataDir}/config/traefik/traefik_config.yml - - - - ${pkgs.writeText "${cfg.name}-traefik-config.yml" traefikConfigText}"
      "L+ ${dataDir}/config/traefik/dynamic_config.yml - - - - ${pkgs.writeText "${cfg.name}-dynamic-config.yml" dynamicConfigText}"
      "L+ ${dataDir}/config/crowdsec/acquis.d/traefik.yaml - - - - ${pkgs.writeText "${cfg.name}-crowdsec-acquis-traefik.yaml" crowdsecAcquisTraefikText}"
      "L+ ${dataDir}/config/crowdsec/acquis.d/appsec.yaml - - - - ${pkgs.writeText "${cfg.name}-crowdsec-acquis-appsec.yaml" crowdsecAcquisAppsecText}"
      "L+ ${dataDir}/config/crowdsec/profiles.yaml - - - - ${pkgs.writeText "${cfg.name}-crowdsec-profiles.yaml" crowdsecProfilesText}"

      # Secret-bearing config symlinks - targets rendered by the secret.templates entries below
      "L+ ${dataDir}/config/config.yml - - - - ${config.secret.templates."${cfg.name}-config".path}"
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
    };

    secret.templates."${cfg.name}-env" = {
      filemode = "0400";
      content = ''
        CF_DNS_API_TOKEN=${config.secret.ref."${cfg.name}/cloudflareApiToken"}
      '';
      secrets."${cfg.name}/cloudflareApiToken".sopsFile = cfg.sopsFile;
    };

    # Periodic MaxMind GeoLite2 refresh - same GitHub mirror the upstream installer pulls from (no
    # MaxMind account/license key needed). These are point-in-time snapshots (IP-to-country/ASN
    # mappings drift as blocks get reallocated), hence the weekly timer rather than a one-shot fetch.
    systemd.services."${cfg.name}-geolite-refresh" = {
      description = "Refresh Pangolin's MaxMind GeoLite2 databases";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = [ pkgs.curl pkgs.gnutar pkgs.coreutils ];
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
      after = [ "network-online.target" "podman.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      environment.CONFIG_REV = configRev;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = dataDir;
        ExecStart = "${pkgs.podman-compose}/bin/podman-compose -f docker-compose.yml -p ${cfg.name} up -d";
        ExecStop = "${pkgs.podman-compose}/bin/podman-compose -f docker-compose.yml -p ${cfg.name} down";
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
        dynCfg=${dataDir}/config/traefik/dynamic_config.yml
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
