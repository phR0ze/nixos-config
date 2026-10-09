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
#   already published it" gotcha entirely rather than closing it after the fact. Traefik's own `web`
#   entrypoint, its `ping`, and upstream's http->https redirect router are dropped too, so nothing
#   listens on :80 even inside the container. Any router Pangolin generates on its default
#   `traefik.http_entrypoint` (`web`) is skipped by Traefik with an "entryPoint web doesn't exist"
#   log line instead - only plain-HTTP routes are lost, which is the point.
# - No HTTP/3: upstream's `http3` block on websecure and its `443/udp` publish are both dropped, so
#   only 443/tcp is exposed - nothing here needs QUIC, and it's one less listener to harden.
# - CrowdSec `COLLECTIONS` matches upstream's own `--crowdsec` installer default
#   (`traefik`/`appsec-virtual-patching`/`appsec-generic-rules`) plus `http-cve` - a maintained,
#   HTTP-CVE-exploitation-detection collection recommended for any internet-facing deployment,
#   `http-dos` (application-layer DoS scenarios over the same Traefik logs), and `appsec-crs`
#   (OWASP Core Rule Set). CRS runs out-of-band only - its `crowdsecurity/crs` appsec config is
#   loaded after `appsec-default` in the AppSec acquisition, so it never blocks a request itself,
#   just raises alerts that ban repeat offenders via `crowdsec-appsec-outofband`. Blocking CRS
#   (`appsec-crs-inband`) is too false-positive-prone without per-app tuning.
#   `base-http-scenarios` is deliberately not listed separately - it's already a dependency of the
#   `traefik` collection itself, so adding it again is a no-op.
# - No telemetry: Pangolin's `anonymous_usage` off, Traefik's release check/anonymous stats off.
# - Traefik's API/dashboard off (upstream ships `api.insecure: true`) - nothing here uses it.
# - `aliasHeadersStrategy: delete` on the websecure entrypoint (Traefik 3.7+) - see the entryPoints note.
# - CrowdSec bouncer trusts no forwarded headers and no RFC1918 ranges - see crowdsecMiddlewareText.
# - No captcha profile: upstream's turns HTTP-scenario alerts into captcha decisions, which need a
#   captcha provider (e.g. Turnstile) configured in the bouncer. Without one they're bans instead.
# - Gerbil drops `SYS_MODULE` (the host preloads `wireguard`, and lockKernelModules makes the cap
#   inert anyway) and mounts only `config/gerbil` for its key rather than all of `config/`, which
#   holds the server secret and acme.json's private keys.
# - Every container gets `no-new-privileges`, and traefik drops all caps but `NET_BIND_SERVICE`.
#   Without `DAC_OVERRIDE`, root can't create Traefik's default `./plugins-storage` in the image's
#   read-only (0555) `/`, which silently disables the badger and crowdsec plugins and fails every
#   router using them (hosts/vm-vps1, 2026-10-07). So it gets its own root-owned dir mounted there,
#   outside `config/` so pangolin's mount doesn't see it.
# - `allow_raw_resources` off by default (`allowRawResources`).
# - One CrowdSec for the whole host: the crowdsec container runs as an agent only
#   (`DISABLE_LOCAL_API`). It still parses Traefik's logs and serves AppSec, but its alerts go to
#   the host's LAPI (services.native.crowdsec), and Traefik's bouncer pulls decisions from there
#   too. So SSH, port-scan, Traefik and AppSec detections share one decision list, one
#   escalating-ban profile, one allowlist and one CAPI/Console identity, and every ban is enforced
#   by both Traefik and the host firewall (which covers the WireGuard ports too). Upstream runs a
#   self-contained LAPI in the container instead.
# - No geo-blocking in Traefik: the host's prerouting geo-block (devices.network.harden, asserted
#   below) drops non-US connections to every published port before they reach any container.
# ### Secrets
# `sopsFile` must point at a `secrets.enc.yaml` holding (key names configurable via the `*Ref`
# options, always nested under `<name>/`):
# - `pangolin/serverSecret`  - session/token signing key (`openssl rand -base64 32`)
# - `pangolin/cloudflareApiToken` - scoped Cloudflare API token (Zone:DNS:Edit + Zone:Zone:Read) for
#   the DNS-01 challenge
# - `crowdsec` <-> Traefik bouncer key
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.services.oci.pangolin;
  dataDir = "/var/lib/${cfg.name}";
  serverSecretKey = "${cfg.name}/${cfg.serverSecretRef}";
  cloudflareApiTokenKey = "${cfg.name}/${cfg.cloudflareApiTokenRef}";

  # Interface names following the fleet's podman conventions (see funcs/service.nix): the stack's
  # bridge as "podman-<name>" (so the `iifname "podman*"` DNS/harden rules cover it, same as before
  # when podman auto-named it podmanN) and each container's host-side veth as "veth-<container>"
  # rather than netavark's anonymous vethN. traefik shares gerbil's netns, so it has no veth.
  # - The bridge name goes through the network's `driver_opts` (podman's documented
  #   `com.docker.network.bridge.name`).
  # - podman-compose (verified 1.5.0/1.6.0) has no field for podman's `host_interface_name`, but it appends
  #   `x-podman.interface_name` verbatim into `--network=<net>:interface_name=<value>`, so a value
  #   of `eth0,host_interface_name=<veth>` passes it through (eth0 is the in-container default
  #   anyway). Relies on that unescaped concatenation - if a podman-compose bump ever validates the
  #   value, the stack fails to start (visible on hosts/vm-vps1 first); drop the suffix then.
  bridge = f.contBridge cfg.name;
  vethOpt = container: "\"eth0,host_interface_name=${f.contVeth container}\"";

  # Fixed addressing on the stack's network (see the `subnet` option) so the host LAPI on 8080 can
  # be opened to exactly the two containers that use it, rather than the whole bridge. traefik
  # shares gerbil's netns, so its LAPI traffic comes from gerbil's address. pangolin gets a fixed
  # address too, only so netavark's auto-assignment can never take one of the others first.
  gatewayIp = f.hostInSubnet cfg.subnet 1;
  pangolinIp = f.hostInSubnet cfg.subnet 2;
  gerbilIp = f.hostInSubnet cfg.subnet 3;
  crowdsecIp = f.hostInSubnet cfg.subnet 4;

  # The host's CrowdSec LAPI (services.native.crowdsec), the single hub this stack's crowdsec agent
  # reports to and Traefik's bouncer pulls decisions from. podman puts `host.containers.internal`
  # in every container's /etc/hosts; whichever host address it resolves to, the traffic enters on
  # this stack's bridge, the only interface 8080 is opened on.
  lapiHost = "host.containers.internal:8080";

  # Credentials the crowdsec-agent unit registers with the host LAPI: the agent's
  # AGENT_USERNAME/AGENT_PASSWORD env file and the Traefik bouncer's API key
  agentStateDir = "/var/lib/${cfg.name}-crowdsec-agent";
  agentEnvFile = "${agentStateDir}/agent.env";
  agentMachine = "${cfg.name}-agent";
  bouncerName = "${cfg.name}-traefik";

  composeText = ''
    name: ${cfg.name}
    services:
      pangolin:
        image: docker.io/fosrl/pangolin:${cfg.pangolinTag}
        container_name: ${cfg.name}
        restart: unless-stopped
        networks:
          default:
            x-podman.interface_name: ${vethOpt cfg.name}
            ipv4_address: ${pangolinIp}
        deploy:
          resources:
            limits:
              memory: ${cfg.memoryLimit}
            reservations:
              memory: ${cfg.memoryReservation}
        security_opt:
          - no-new-privileges:true
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
        networks:
          default:
            x-podman.interface_name: ${vethOpt "gerbil"}
            ipv4_address: ${gerbilIp}
        depends_on:
          pangolin:
            condition: service_healthy
        command:
          - --reachableAt=http://gerbil:3004
          - --generateAndSaveKeyTo=/var/config/key
          - --remoteConfig=http://pangolin:3001/api/v1/
        volumes:
          - ./config/gerbil:/var/config
        security_opt:
          - no-new-privileges:true
        cap_add:
          - NET_ADMIN
        ports:
          - 51820:51820/udp
          - 21820:21820/udp
          - 443:443

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
        security_opt:
          - no-new-privileges:true
        cap_drop:
          - ALL
        cap_add:
          - NET_BIND_SERVICE
        volumes:
          - ./config/traefik:/etc/traefik:ro
          - ./traefik-plugins:/plugins-storage
          - ./config/letsencrypt:/letsencrypt
          - ./config/traefik/logs:/var/log/traefik

      crowdsec:
        image: docker.io/crowdsecurity/crowdsec:${cfg.crowdsecTag}
        container_name: crowdsec
        restart: unless-stopped
        networks:
          default:
            x-podman.interface_name: ${vethOpt "crowdsec"}
            ipv4_address: ${crowdsecIp}
        environment:
          GID: "1000"
          COLLECTIONS: ${lib.concatStringsSep " " cfg.crowdsecCollections}
          PARSERS: crowdsecurity/whitelists
          DISABLE_LOCAL_API: "true"
          LOCAL_API_URL: http://${lapiHost}
        env_file:
          - ${agentEnvFile}
        healthcheck:
          test: ["CMD", "cscli", "lapi", "status"]
          interval: "10s"
          timeout: "5s"
          retries: 3
          start_period: "30s"
        labels:
          - "traefik.enable=false"
        security_opt:
          - no-new-privileges:true
        volumes:
          - ./config/crowdsec:/etc/crowdsec
          - ./config/crowdsec/db:/var/lib/crowdsec/data
          - ./config/traefik/logs:/var/log/traefik

    networks:
      default:
        driver: bridge
        name: ${cfg.name}_frontend
        driver_opts:
          com.docker.network.bridge.name: ${bridge}
        ipam:
          config:
            - subnet: ${cfg.subnet}
              gateway: ${gatewayIp}
  '';

  traefikConfigText = ''
    # No phoning home: no release check (which also sends usage data), no anonymous stats
    global:
      checkNewVersion: false
      sendAnonymousUsage: false

    # Upstream's insecure dashboard/API opens an unauthenticated `traefik` entrypoint on :8080 that
    # nothing here uses - Pangolin feeds Traefik through the http provider below, never its API
    api:
      insecure: false
      dashboard: false

    providers:
      http:
        endpoint: "http://pangolin:3001/api/v1/traefik-config"
        pollInterval: "5s"
      file:
        # Directory (not filename) mode is required for the crowdsec middleware file below to
        # hot-reload - Traefik's single-file mode never watches for changes, only directory mode
        # does. It's written by its own service (atomically, via a non-.yml temp file + mv) and
        # picked up live without restarting traefik.
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

    # aliasHeadersStrategy: delete - drop any request header whose name has a character other than a
    # letter, digit or dash (e.g. `X_Forwarded_For`, `X.Real.Ip`), which backends deriving variable
    # names from headers (CGI/PHP/WSGI/nginx) would read as the real header Traefik manages, letting
    # a client spoof it. Silent drop rather than `reject` (400), matching nginx's own default of
    # ignoring underscored headers. Traefik 3.7+, default `keep`.
    # No `web` (:80) entrypoint at all - certs come from DNS-01, so nothing needs plain HTTP, and
    # Traefik doesn't even listen on it inside the container (see the header's DNS-01 note).
    entryPoints:
      websecure:
        address: ":443"
        transport:
          respondingTimeouts:
            readTimeout: "30m"
        http:
          aliasHeadersStrategy: delete
          tls:
            certResolver: "letsencrypt"
          middlewares:
            - crowdsec@file
          encodedCharacters:
            allowEncodedSlash: true
            allowEncodedQuestionMark: true

    serversTransport:
      insecureSkipVerify: true
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
        # Nothing is allowed, so every request is answered 403 without reaching a backend
        deny-all:
          ipAllowList:
            sourceRange:
              - "127.0.0.1/32"

      routers:
        # Lowest-priority catch-all for requests no other router matches - scanners hitting the
        # bare IP or an unknown hostname. Traefik only runs middlewares on a matched router, so
        # without this they got its built-in 404 and skipped the entrypoint's crowdsec@file
        # (bouncer + AppSec) entirely; now AppSec inspects them like any other request. crowdsec@file
        # isn't listed here since entrypoint middlewares already apply to every websecure router.
        # Answers 403 rather than a 5xx so it stays inside the access log's 2xx/4xx filter, which
        # the Traefik-log scenarios read. `tls: {}` keeps it off the entrypoint's ACME resolver,
        # which can't issue for a rule with no Host.
        catchall-router:
          rule: "PathPrefix(`/`)"
          priority: 1
          service: noop@internal
          entryPoints:
            - websecure
          middlewares:
            - deny-all
          tls: {}

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

  # The crowdsec bouncer middleware lives in its own dynamic-config file, written by the
  # crowdsec-bouncer service below (with @LAPI_KEY@ substituted) rather than by tmpfiles. NixOS
  # re-runs tmpfiles on *every* switch (switch-to-configuration always restarts
  # sysinit-reactivation.target, which pulls in systemd-tmpfiles-resetup), so when the key lived in
  # the tmpfiles-managed dynamic_config.yml every switch silently reverted it to upstream's
  # placeholder - and Traefik's directory watch hot-loaded that, failing every websecure request
  # (dashboard, Newt's API/websocket) at the bouncer until the next stack restart re-patched it.
  #
  # Client-IP trust is narrowed from upstream's template, since `clientTrustedIPs` skips the bouncer
  # entirely - LAPI decisions and AppSec alike:
  # - `forwardedHeadersTrustedIPs` is empty (upstream: 0.0.0.0/0). Traefik sits at the edge and sees
  #   each client's real address directly, so the plugin never needs X-Forwarded-For - trusting it
  #   from everyone means a single `X-Forwarded-For: <trusted IP>` header skips CrowdSec the moment
  #   anything upstream of the plugin stops overwriting it (e.g. `forwardedHeaders.insecure`).
  # - No RFC1918 ranges (upstream: 10/8, 172.16/12, 192.168/16). No legitimate client reaches a VPS
  #   from them - only the stack's own podman bridge or a provider's shared private network would.
  #   A host that does front a LAN (e.g. hosts/vm-vps1) lists it explicitly in `trustedClients`.
  crowdsecMiddlewareText = ''
    http:
      middlewares:
        crowdsec:
          plugin:
            crowdsec:
              enabled: true
              logLevel: INFO
              # stream: keep a local copy of the ban list, refreshed every 15s, rather than asking
              # the LAPI on every request (live). The LAPI is the host's now, which restarts daily
              # with the hub update; stream rides that out instead of returning 403s. After 8
              # failed refreshes in a row (~2min) it fails closed and blocks everything.
              updateIntervalSeconds: 15
              updateMaxFailure: 8
              httpTimeoutSeconds: 10
              crowdsecMode: stream
              crowdsecAppsecEnabled: true
              crowdsecAppsecHost: crowdsec:7422
              crowdsecAppsecFailureBlock: true
              crowdsecAppsecUnreachableBlock: true
              crowdsecAppsecBodyLimit: 10485760
              crowdsecLapiKey: "@LAPI_KEY@"
              crowdsecLapiHost: ${lapiHost}
              crowdsecLapiScheme: http
              forwardedHeadersTrustedIPs: []
              clientTrustedIPs:
                - "100.89.137.0/20" # Gerbil's default site-tunnel CGNAT range - keep in sync with any override
    ${crowdsecTrustedAllowList}
  '';

  # trustedClients entries (the host's `network.allowList`) appended to clientTrustedIPs, which
  # skips the bouncer entirely - LAPI decisions and AppSec - for those clients. Keeps a trusted
  # site (e.g. the homelab's Newt registering over the API/websocket) from being locked out by a
  # community-blocklist or captcha decision on its public IP, or by AppSec being unreachable while
  # crowdsec restarts. Explicit absolute-column lines for the same reason as wildcardTls above.
  crowdsecTrustedAllowList = lib.concatMapStringsSep "\n"
    (ip: "            - \"${ip}\"") cfg.trustedClients;

  crowdsecAcquisTraefikText = ''
    poll_without_inotify: false
    filenames:
      - /var/log/traefik/*.log
    labels:
      type: traefik
  '';

  crowdsecAcquisAppsecText = ''
    listen_addr: 0.0.0.0:7422
    appsec_configs:
      - crowdsecurity/appsec-default
      - crowdsecurity/crs
    name: myAppSecComponent
    source: appsec
    labels:
      type: appsec
  '';

  # Forces the systemd unit definition itself to change whenever any rendered config changes -
  # otherwise a `nixos-rebuild switch` that only updates a symlink target doesn't bump the unit's
  # own hash, so NixOS never restarts it and podman-compose never re-applies the new config.
  configRev = builtins.hashString "sha256" (
    composeText + traefikConfigText + dynamicConfigText + crowdsecAcquisTraefikText
    + crowdsecAcquisAppsecText
  );
in
{
  options.services.oci.pangolin = {
    enable = lib.mkEnableOption "Deploy Pangolin (pangolin+gerbil+traefik+crowdsec) via podman-compose";

    name = lib.mkOption {
      description = "Compose project / container-name prefix";
      type = types.str;
      default = "pangolin";
    };

    pangolinTag = lib.mkOption {
      description = "fosrl/pangolin image tag - check github.com/fosrl/pangolin/releases for current";
      type = types.str;
      example = "ee-1.21.1";
    };

    gerbilTag = lib.mkOption {
      description = "fosrl/gerbil image tag - check github.com/fosrl/gerbil/releases for current";
      type = types.str;
      example = "1.5.1";
    };

    traefikTag = lib.mkOption {
      description = "traefik image tag - check Traefik's release page for current";
      type = types.str;
      example = "v3.7";
    };

    crowdsecTag = lib.mkOption {
      description = ''
        crowdsecurity/crowdsec image tag - pinned deliberately (upstream's own `--crowdsec`
        installer template floats `:latest`), see the module-level "Documented exceptions" note.
        Check github.com/crowdsecurity/crowdsec/releases for current.
      '';
      type = types.str;
      example = "v1.7.8";
    };

    badgerPluginVersion = lib.mkOption {
      description = "fosrl/badger Traefik plugin version - check github.com/fosrl/badger/releases";
      type = types.str;
      example = "v1.5.0";
    };

    crowdsecPluginVersion = lib.mkOption {
      description = ''
        maxlerebourg/crowdsec-bouncer-traefik-plugin version - check that repo's releases
      '';
      type = types.str;
      example = "v1.4.4";
    };

    crowdsecCollections = lib.mkOption {
      description = "CrowdSec hub collections installed into the Traefik-facing engine";
      type = types.listOf types.str;
      default = [
        "crowdsecurity/traefik"
        "crowdsecurity/http-cve"
        "crowdsecurity/appsec-virtual-patching"
        "crowdsecurity/appsec-generic-rules"
        "crowdsecurity/http-dos"
        "crowdsecurity/appsec-crs"
      ];
    };

    baseDomain = lib.mkOption {
      description = ''
        Base domain resources/wildcard cert are issued under, e.g. example.com. Nullable so
        `modules/default.nix` can unconditionally forward `machine.services.oci.pangolin.baseDomain`
        (host args) here without an existence check - see the `enable`-gated assertion below for
        the actual requirement.
      '';
      type = types.nullOr types.str;
      default = null;
    };

    dashboardDomain = lib.mkOption {
      description = "Pangolin dashboard hostname";
      type = types.str;
      # toString so a missing baseDomain reaches the assertion below instead of a coercion error
      default = "pangolin.${toString cfg.baseDomain}";
    };

    acmeEmail = lib.mkOption {
      description = ''
        Contact email for Let's Encrypt ACME registration. Nullable so `modules/default.nix` can
        unconditionally forward `host.services.oci.pangolin.acmeEmail` (host args) here without
        an existence check - see the `enable`-gated assertion below for the actual requirement.
      '';
      type = types.nullOr types.str;
      default = null;
    };

    memoryLimit = lib.mkOption {
      description = "Soft memory ceiling for the pangolin container - see Documented exceptions";
      type = types.str;
      default = "1g";
    };

    subnet = lib.mkOption {
      description = ''
        Fixed /24 for the stack's podman network. The containers get fixed addresses in it
        (gateway .1, pangolin .2, gerbil/traefik .3, crowdsec .4), and the host LAPI on 8080 is
        only opened to gerbil/traefik and crowdsec. Must not overlap any other podman network on
        the host.
      '';
      type = types.strMatching "[0-9]+\\.[0-9]+\\.[0-9]+\\.0/24";
      default = "10.89.130.0/24";
    };

    memoryReservation = lib.mkOption {
      description = "Memory reservation for the pangolin container";
      type = types.str;
      default = "512m";
    };

    trustedClients = lib.mkOption {
      description = ''
        CIDRs/IPs appended to the Traefik crowdsec bouncer's `clientTrustedIPs`, so these clients
        skip CrowdSec entirely (LAPI decisions and AppSec) - e.g. the homelab's public IP, so its
        Newt can't be locked out of registering. Normally forwarded from `host.network.allowList`,
        which also exempts them from the host geo-block. Only list addresses you control: never
        shared/CGNAT ranges, which would exempt strangers too.
      '';
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "203.0.113.7" "198.51.100.0/24" ];
    };

    sopsFile = lib.mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "./secrets.enc.yaml";
      description = ''
        Path to the sops-encrypted file holding the `serverSecretRef` and
        `cloudflareApiTokenRef` keys - see the module-level Secrets note. Nullable so
        `modules/default.nix` can forward `host.sopsFile` unconditionally - see the `enable`-gated
        assertion below for the actual requirement.
      '';
    };

    serverSecretRef = lib.mkOption {
      description = ''
        Key under `<name>/` within `sopsFile` holding Pangolin's session/token signing key,
        referenced as `''${name}/''${serverSecretRef}`.
      '';
      type = types.str;
      default = "serverSecret";
    };

    cloudflareApiTokenRef = lib.mkOption {
      description = ''
        Key under `<name>/` within `sopsFile` holding the Cloudflare API token (Zone:DNS:Edit +
        Zone:Zone:Read) used for the DNS-01 challenge, referenced as
        `''${name}/''${cloudflareApiTokenRef}`.
      '';
      type = types.str;
      default = "cloudflareApiToken";
    };

    disableUserCreateOrg = lib.mkOption {
      description = "Whether to prevent non-admin users from creating their own organization";
      type = types.bool;
      default = true;
    };

    allowRawResources = lib.mkOption {
      description = ''
        Whether raw TCP/UDP resources can be created. Off by default: they each need their own
        port published on gerbil, and nothing here uses them.
      '';
      type = types.bool;
      default = false;
    };

    rateLimitWindowMinutes = lib.mkOption {
      description = "Global rate-limit window, in minutes";
      type = types.int;
      default = 1;
    };

    rateLimitMaxRequests = lib.mkOption {
      description = "Global rate-limit max requests per window";
      type = types.int;
      default = 100;
    };

    dashboardSessionLengthHours = lib.mkOption {
      description = ''
        Install-wide dashboard login session length, in hours (Pangolin's default is 720, i.e. 30
        days - long-lived for an admin-facing UI). Per-org session policy in the dashboard layers
        on top of this.
      '';
      type = types.ints.positive;
      default = 24;
    };

    resourceSessionLengthHours = lib.mkOption {
      description = ''
        Install-wide session length for users authenticating to exposed resources, in hours
        (Pangolin's default is 720). Kept longer than the dashboard's since end users hit resources
        day to day.
      '';
      type = types.ints.positive;
      default = 168;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = cfg.baseDomain != null && cfg.baseDomain != ""; message = "services.oci.pangolin requires 'baseDomain', normally forwarded from 'host.network.domain'"; }
      { assertion = cfg.acmeEmail != null; message = "services.oci.pangolin requires 'acmeEmail'"; }
      { assertion = cfg.sopsFile != null; message = "services.oci.pangolin requires 'sopsFile', normally forwarded from 'host.sopsFile'"; }
      # Country filtering for every port this stack publishes (443, WireGuard) is the host's
      # prerouting geo-block - there's no second one in Traefik
      { assertion = config.devices.network.harden.enable;
        message = "services.oci.pangolin requires devices.network.harden.enable - its geo-block is the only country filter in front of the stack";
      }
      { assertion = config.services.native.crowdsec.enable;
        message = "services.oci.pangolin requires services.native.crowdsec - its crowdsec agent and Traefik bouncer use the host's LAPI";
      }
      # CrowdSec agents must not be newer than the LAPI they report to
      { assertion = lib.versionAtLeast config.services.crowdsec.package.version (lib.removePrefix "v" cfg.crowdsecTag);
        message = "services.oci.pangolin.crowdsecTag (${cfg.crowdsecTag}) is newer than the host's CrowdSec LAPI (${config.services.crowdsec.package.version})";
      }
    ];

    virtualization.podman.enable = true;

    # Started once the network is up, after boot (see devices.network.onlineServices): at startup
    # traefik downloads its plugins and requests certs, crowdsec updates its hub, and pangolin
    # looks up its public IP. The bouncer is listed too, or multi-user.target would pull the stack
    # back into boot through its `requires`.
    devices.network.onlineServices = [
      "${cfg.name}-stack" "${cfg.name}-crowdsec-bouncer" "${cfg.name}-crowdsec-agent"
    ];

    # Modules gerbil needs on the host, preloaded rather than left to autoload: devices.kernel.harden's
    # lockKernelModules blocks loading anything once the default target is reached, which only
    # happens to land after gerbil's first start - a gerbil restart later on would fail. Besides
    # its WireGuard interface, gerbil's iptables-nft MSS-clamping and wg0 INPUT rules pull in the
    # xt_* matches through nft_compat (confirmed via lsmod, hosts/vm-vps1 2026-10-07).
    boot.kernelModules = [ "wireguard" "nft_compat" "xt_TCPMSS" "xt_conntrack" "xt_tcpudp" ];

    # Same caveat as every other services.oci.* module publishing container ports: podman's own
    # NAT/forward rules reach these regardless of networking.firewall - these entries are
    # documentation/consistency, not the actual gate. The real gates for them are the prerouting
    # chains: services.native.crowdsec's ban set and devices.network.harden's geo-block.
    networking.firewall.allowedTCPPorts = [ 443 ];
    networking.firewall.allowedUDPPorts = [ 51820 21820 ];

    # The host LAPI (see lapiHost), reachable only from the two containers that use it: the
    # crowdsec agent and Traefik's bouncer (in gerbil's netns). The pangolin app container is on
    # the same bridge but has no business with the LAPI. The source match is safe from spoofing:
    # NixOS's reverse-path filter drops packets claiming these addresses on any other interface,
    # and the addresses are fixed so nothing else on the bridge can be assigned them.
    networking.firewall.extraInputRules = ''
      iifname "${bridge}" ip saddr { ${gerbilIp}, ${crowdsecIp} } tcp dport 8080 accept
    '';

    # Non-secret config - rendered directly into the Nix store and symlinked into place, so a
    # nixos-rebuild switch always reflects the current module source. Runtime-writable state
    # (acme.json, crowdsec's db, access logs, Pangolin's own db/, mmdb files) lives in plain
    # directories created below, never symlinked.
    systemd.tmpfiles.rules = [
      "d ${dataDir} 0750 root root -"
      "d ${dataDir}/config 0750 root root -"
      "d ${dataDir}/config/db 0750 root root -"
      "d ${dataDir}/config/gerbil 0700 root root -"
      "d ${dataDir}/config/logs 0750 root root -"
      "d ${dataDir}/config/letsencrypt 0700 root root -"
      "d ${dataDir}/config/traefik 0750 root root -"
      "d ${dataDir}/config/traefik/dynamic 0750 root root -"
      "d ${dataDir}/config/traefik/logs 0750 root root -"
      "d ${dataDir}/config/crowdsec 0750 root root -"
      "d ${dataDir}/config/crowdsec/db 0750 root root -"
      "d ${dataDir}/config/crowdsec/acquis.d 0750 root root -"
      "d ${dataDir}/state 0700 root root -"
      "d ${dataDir}/traefik-plugins 0700 root root -"

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
      # any subsequent `nixos-rebuild switch` (found while verifying a since-removed Traefik
      # geo-allowlist feature never took effect despite a clean build - hosts/vm-vps1 testing,
      # 2026-09-22). `r` doesn't error if the path is already missing, so this is safe on a
      # first-ever activation too.
      "r ${dataDir}/config/traefik/traefik_config.yml"
      "C+ ${dataDir}/config/traefik/traefik_config.yml - - - - ${pkgs.writeText "${cfg.name}-traefik-config.yml" traefikConfigText}"
      "r ${dataDir}/config/traefik/dynamic/dynamic_config.yml"
      "C+ ${dataDir}/config/traefik/dynamic/dynamic_config.yml - - - - ${pkgs.writeText "${cfg.name}-dynamic-config.yml" dynamicConfigText}"
      # Left over from the removed Traefik geo-block (the host's prerouting geo-block covers it)
      "r ${dataDir}/config/traefik/dynamic/geo-allowlist.yml"
      "r ${dataDir}/state/us-cidrs.txt"
      "r ${dataDir}/config/crowdsec/acquis.d/traefik.yaml"
      "C+ ${dataDir}/config/crowdsec/acquis.d/traefik.yaml - - - - ${pkgs.writeText "${cfg.name}-crowdsec-acquis-traefik.yaml" crowdsecAcquisTraefikText}"
      "r ${dataDir}/config/crowdsec/acquis.d/appsec.yaml"
      "C+ ${dataDir}/config/crowdsec/acquis.d/appsec.yaml - - - - ${pkgs.writeText "${cfg.name}-crowdsec-acquis-appsec.yaml" crowdsecAcquisAppsecText}"
      # Left over from when the container ran its own LAPI with 4h bans; profiles now live on the
      # host LAPI, and an agent never reads this
      "r ${dataDir}/config/crowdsec/profiles.yaml"

      # Secret-bearing config - targets rendered by the secret.templates entries below. Same
      # never-refreshes bug applies here too - without the `r`, rotating
      # serverSecretRef or cloudflareApiTokenRef would silently never reach the
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
                anonymous_usage: false
            save_logs: true
            log_failed_attempts: true

        domains:
            domain1:
                base_domain: "${cfg.baseDomain}"
                prefer_wildcard_cert: true
                cert_resolver: "letsencrypt"

        server:
            secret: "${config.secret.ref.${serverSecretKey}}"
            maxmind_db_path: "./config/GeoLite2-Country.mmdb"
            maxmind_asn_path: "./config/GeoLite2-ASN.mmdb"
            cors:
                origins: ["https://${cfg.dashboardDomain}"]
                methods: ["GET", "POST", "PUT", "DELETE", "PATCH"]
                allowed_headers: ["X-CSRF-Token", "Content-Type"]
                credentials: false
            trust_proxy: 1
            dashboard_session_length_hours: ${toString cfg.dashboardSessionLengthHours}
            resource_session_length_hours: ${toString cfg.resourceSessionLengthHours}

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
            allow_raw_resources: ${lib.boolToString cfg.allowRawResources}
      '';
      secrets.${serverSecretKey}.sopsFile = cfg.sopsFile;
      # configRev below only hashes the *plaintext* configs, so a rotated serverSecret changes
      # this rendered file without changing the stack unit's own definition - nothing would
      # restart it and the containers would keep running against the old value
      restartUnits = [ "${cfg.name}-stack.service" ];
    };

    secret.templates."${cfg.name}-env" = {
      filemode = "0400";
      content = ''
        CF_DNS_API_TOKEN=${config.secret.ref.${cloudflareApiTokenKey}}
      '';
      secrets.${cloudflareApiTokenKey}.sopsFile = cfg.sopsFile;
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
      # Boot doesn't wait on networking, so DNS may not resolve yet on the first attempt - retry
      # rather than staying failed until next week's timer
      serviceConfig = {
        Type = "oneshot";
        Restart = "on-failure";
        RestartSec = 60;
      };
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
    # Traefik holds the file open, so after the rename it would keep writing to access.log.1 -
    # outside crowdsec's `*.log` acquisition glob, blinding it from the first rotation on, and later
    # compressed/deleted out from under the open handle. USR1 makes Traefik reopen its log files
    # (its documented rotation hook), unlike copytruncate, which drops lines written between the
    # copy and the truncate. `|| true` so a stopped stack doesn't fail the rotation.
    services.logrotate.settings."${cfg.name}-traefik" = {
      files = [ "${dataDir}/config/traefik/logs/access.log" ];
      frequency = "daily";
      rotate = 7;
      compress = true;
      delaycompress = true;
      missingok = true;
      notifempty = true;
      sharedscripts = true;
      postrotate = "${config.virtualisation.podman.package}/bin/podman kill --signal USR1 traefik >/dev/null 2>&1 || true";
    };

    # Have services.native.alerts watch the stack. Its unit is a oneshot that stays `active` however
    # the containers fare, so a crash-looping container never shows up as a failed unit; and every
    # image is pinned, so nothing else notices a new upstream release. As a public-facing CrowdSec
    # host, it also gets the daily security digest - the host's own `cscli` covers this stack's
    # decisions too, since its crowdsec container is only an agent of the host LAPI.
    services.native.alerts.enable = lib.mkDefault true;
    services.native.alerts.securityDigest.enable = true;
    services.native.alerts.containers.units."${cfg.name}-stack" = [ cfg.name "gerbil" "traefik" "crowdsec" ];
    services.native.alerts.imageUpdates.images = {
      # EE and CE ship from the same release as separate image tags (`ee-` is handled by alerts)
      pangolin = { tag = cfg.pangolinTag; repo = "fosrl/pangolin"; };
      gerbil = { tag = cfg.gerbilTag; repo = "fosrl/gerbil"; };
      traefik = { tag = cfg.traefikTag; repo = "traefik/traefik"; };
      crowdsec = { tag = cfg.crowdsecTag; repo = "crowdsecurity/crowdsec"; };
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
      # The crowdsec container is an agent of the host LAPI and traefik waits on it turning healthy
      # (`cscli lapi status`), so the host LAPI and the agent's credentials must be up first.
      after = [
        "podman.service"
        "${cfg.name}-geolite-refresh.service"
        "crowdsec.service"
        "${cfg.name}-crowdsec-agent.service"
      ];
      wants = [
        "${cfg.name}-geolite-refresh.service"
        "crowdsec.service"
      ];
      requires = [ "${cfg.name}-crowdsec-agent.service" ];
      environment.CONFIG_REV = configRev;
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = dataDir;
        # Every start begins from a clean slate: the project's containers are always torn down
        # first, so `up` creates every container fresh from the current compose file. Containers
        # persist across reboots (ExecStop's `down` doesn't always get to run at shutdown), and
        # podman-compose's own change detection can't be trusted to replace them: it does notice a
        # changed config hash, but only recreates *running* dependents alongside the changed
        # service, so at boot (everything exited) changing gerbil skips traefik, which shares
        # gerbil's netns. podman then refuses to remove gerbil ("has dependent containers which must
        # be removed before it"), the create fails on the name in use, and podman-compose silently
        # starts the stale container and exits 0 - leaving gerbil publishing a port removed from
        # the compose file a day earlier (hosts/vm-vps1, 2026-10-06). `down` removes dependents
        # first, so it can't hit that.
        #
        # podman-compose also only creates a missing network, never updates one, so an existing
        # network whose bridge or subnet doesn't match - e.g. the auto-named podmanN from before
        # `bridge` was set (hosts/vm-vps1, 2026-10-05), or an auto-assigned subnet from before
        # `subnet` was - is removed here for `up` to recreate.
        ExecStartPre = pkgs.writeShellScript "${cfg.name}-stack-reset" ''
          set -euo pipefail
          ${pkgs.podman-compose}/bin/podman-compose -f docker-compose.yml -p ${cfg.name} down
          # Gerbil used to mount all of config/ and keep its key at config/key - move it into
          # gerbil's own dir so its WireGuard identity survives narrowing that mount
          if [ -s config/key ] && [ ! -e config/gerbil/key ]; then
            mv config/key config/gerbil/key
          fi
          net=${cfg.name}_frontend
          if ${pkgs.podman}/bin/podman network exists "$net" \
              && [ "$(${pkgs.podman}/bin/podman network inspect --format '{{.NetworkInterface}} {{range .Subnets}}{{.Subnet}}{{end}}' "$net")" != "${bridge} ${cfg.subnet}" ]; then
            ${pkgs.podman}/bin/podman network rm "$net"
          fi
        '';
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

    # Registers this stack with the host LAPI, the single CrowdSec hub: the crowdsec container as an
    # agent (machine) that sends its Traefik/AppSec alerts there, and Traefik's bouncer plugin
    # with its own API key. Both credentials can only be generated by the running LAPI, so they
    # can't be sops-sourced like server/cloudflare above. Runs as the crowdsec user through the
    # host's `cscli` wrapper, like services.native.crowdsec's firewall-bouncer registration, and
    # mirrors its recovery pattern: if the LAPI entry or the local credential file is missing,
    # delete and recreate both rather than retrying (`add` refuses an existing name).
    systemd.services."${cfg.name}-crowdsec-agent" = {
      description = "Register Pangolin's CrowdSec agent and Traefik bouncer with the host LAPI";
      after = [ "crowdsec.service" ];
      wants = [ "crowdsec.service" ];
      path = [ pkgs.jq pkgs.openssl config.system.path ];
      script = ''
        set -euo pipefail
        stateDir=${agentStateDir}

        for i in $(seq 1 30); do
          cscli lapi status >/dev/null 2>&1 && break
          sleep 2
        done

        if ! cscli machines list -o json | jq -e 'any(.[]; .machineId == "${agentMachine}")' >/dev/null \
            || [ ! -s "$stateDir/agent.env" ]; then
          rm -f "$stateDir/agent.env"
          password=$(openssl rand -hex 32)
          cscli machines add ${agentMachine} --password "$password" -f /dev/null --force >/dev/null
          printf 'AGENT_USERNAME=%s\nAGENT_PASSWORD=%s\n' ${agentMachine} "$password" > "$stateDir/agent.env.tmp"
          mv -f "$stateDir/agent.env.tmp" "$stateDir/agent.env"
        fi

        if ! cscli bouncers list -o json | jq -e 'any(.[]; .name == "${bouncerName}")' >/dev/null \
            || [ ! -s "$stateDir/bouncer-key" ]; then
          rm -f "$stateDir/bouncer-key"
          cscli bouncers delete --ignore-missing -- ${bouncerName} >/dev/null
          if ! cscli bouncers add --output raw -- ${bouncerName} > "$stateDir/bouncer-key"; then
            rm -f "$stateDir/bouncer-key"
            exit 1
          fi
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = config.services.crowdsec.user;
        Group = config.services.crowdsec.group;
        StateDirectory = "${cfg.name}-crowdsec-agent";
        UMask = "0077";
      };
    };

    # Renders crowdsecMiddlewareText with the bouncer key into its own dynamic-config file (never
    # touched by tmpfiles - see crowdsecMiddlewareText's comment), only rewriting it when the
    # content differs. Traefik's directory watch picks the change up live, so traefik is never
    # restarted (which would drop every tunnel's connection). The template's store path is in this
    # script, so a template change alters the unit and NixOS re-runs it on switch; a stack restart
    # re-runs it via `requires`.
    systemd.services."${cfg.name}-crowdsec-bouncer" = {
      description = "Apply the LAPI key to Pangolin's Traefik CrowdSec bouncer";
      after = [ "${cfg.name}-stack.service" "${cfg.name}-crowdsec-agent.service" ];
      requires = [ "${cfg.name}-stack.service" "${cfg.name}-crowdsec-agent.service" ];
      path = [ pkgs.coreutils pkgs.diffutils ];
      serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
      script = ''
        set -euo pipefail
        dynDir=${dataDir}/config/traefik/dynamic
        dest=$dynDir/crowdsec.yml

        key=$(< ${agentStateDir}/bouncer-key)
        template=$(< ${pkgs.writeText "${cfg.name}-crowdsec-middleware.yml" crowdsecMiddlewareText})
        tmp=$(mktemp "$dynDir/.crowdsec.XXXXXX.tmp")
        trap 'rm -f "$tmp"' EXIT
        printf '%s\n' "''${template//@LAPI_KEY@/$key}" > "$tmp"
        chmod 0600 "$tmp"
        if ! cmp -s "$tmp" "$dest"; then
          mv -f "$tmp" "$dest"
        fi
      '';
    };
  };
}
