# Newt configuration
# - https://github.com/fosrl/newt
# - https://docs.pangolin.net/manage/sites/understanding-sites
#
# ### Description
# Newt is Pangolin's site connector — a fully user-space WireGuard tunnel client (netstack-based, no
# host TUN device, no NET_ADMIN) that dials outbound from this homelab to a Pangolin VPS and proxies
# traffic for whatever internal services are exposed as Resources in the Pangolin dashboard. See the
# tech-docs Pangolin doc (`networking/reverse_tunnel/pangolin/README.md`) for the VPS-side setup this
# connects to, and its "Create a Site describing your server" section for where `pangolin.url`/`id`/
# secret come from.
#
# ### Instances
# One Newt is one site connection to one Pangolin server, so each Pangolin server this host joins
# is its own named entry in `instances`, run as its own container (`newt-<instance>`) on its own
# podman network with its own egress rule and secret. Everything else (tag, user, hardening, log
# level) is shared. Every instance defined in `args.enc.yaml` runs once the module is enabled; its
# own `enable` defaults to on and only needs setting to turn one off in the host's
# `configuration.nix`:
# ```nix
#   services.oci.newt = {
#     enable = true; user.uid = 2005; tag = "1.16.0";
#     instances.b.enable = false;   # optional - temporarily drop just this connection
#   };
# ```
# ```yaml
# host:
#   services:
#     oci:
#       newt:
#         instances:
#           a: { id: ..., subnet: 10.89.120.0/24, ip: 10.89.120.2, pangolin: { url: ..., ip: ... } }
# ```
# Keep instance names to 3 characters or fewer: the bridge name `podman-newt-<instance>` is cut to
# the kernel's 15-character limit, and an assertion rejects two instances that collide after that.
#
# ### Deployment Details
# - Outbound-only: Newt registers with Pangolin over HTTPS/WebSocket and tunnels over UDP to Gerbil.
#   No inbound ports are published on this host for this service, so no firewall rule is needed either.
# - Fully user-space WireGuard — no Linux capabilities, no `/dev/net/tun`, so the container runs
#   `--cap-drop=ALL`, non-root, and (by default) with a read-only rootfs.
# - `pangolin.url`/`id` identify *which* site connects, but grant nothing without the secret below.
#   They come from `host.services.oci.newt.instances.<instance>.*` in `args.enc.yaml`, forwarded by
#   modules/default.nix. The secret is `newt/<instance>/clientSecret` in the host's secrets.
# - Get the Endpoint/ID/Secret from the Pangolin dashboard: `Network > Sites > + Add Site > Newt Site
# - Get status with:
#   sudo systemctl status podman-newt-<instance>
# - Tunnel health: Newt maintains HEALTH_FILE while its WireGuard tunnel to Gerbil is up, which the
#   podman healthcheck below reports — `podman healthcheck run newt-<instance>` or the STATUS column
#   of `sudo podman ps`. Report-only: Newt reconnects on its own, so an unhealthy state never kills it.
# - Newt's SSH auth daemon (DISABLE_SSH) is turned off. Its client tunnels (DISABLE_CLIENTS) are on
#   by default for private resources, and off with `allowClients = false`. Each opens more paths
#   into the homelab than the public Resources defined for this site. See "Private resources".
#
# ### Private resources
# `allowClients` lets Pangolin clients (the CLI/desktop apps) reach this site's *private* (ZTNA)
# resources through Newt. Clients always come in through Gerbil's relay (udp/21820 on the Pangolin
# server, already allowed below): Newt only hole-punches towards Gerbil, and replies to any other
# address are rejected, so a direct client<->homelab path never forms. What a client can reach is
# still bounded by "Egress containment": a private resource has to target Caddy on Newt's gateway,
# i.e. `host.containers.internal` (the gateway IP) on 443, never this host's LAN IP. A `Host`-mode
# resource keeps the client's own SNI/Host header, so Caddy routes it like any LAN client. Newt's
# in-tunnel DNS (default 9.9.9.9, which egress rejects) is pointed at that same gateway -
# aardvark-dns, i.e. this host's resolver.
#
# ### Reaching services behind Caddy
# Caddy runs as a native host service (not a container) fronting homarr/oneup/stirling-pdf/
# vaultwarden with TLS, listening on all interfaces. Newt reaches it through its own podman network's
# gateway, aliased as `host.containers.internal` via `--add-host`, so Resources don't depend on this
# host's LAN IP. To expose a Caddy-fronted app, create an HTTP
# Resource in the Pangolin dashboard with:
# - Target: method `https`, host `host.containers.internal`, port `443`. Pangolin terminates the
#   public TLS at its own Traefik and opens a fresh TLS connection to Caddy *without SNI*
#   (fosrl/pangolin#207) — Caddy's `default_sni` picks its wildcard cert, and routing is by the
#   `Host` header. There's no TLS passthrough involved.
# - A custom Host header of `<subdomain>.<this host's network.domain>` if the public hostname on
#   Pangolin differs from the Caddy vhost; Traefik passes the public Host through unchanged otherwise.
# Apps not fronted by Caddy can't be targeted at all — see "Egress containment" below.
#
# Caddy sees all of this traffic arriving from each instance's fixed container `ip` (host-local, so
# it's never SNAT'd), so modules/default.nix adds every enabled instance's IP to Caddy's
# `trustedProxies` whenever both are enabled —
# backends (e.g. Vaultwarden's login rate limiting) then see real client IPs from Traefik's
# `X-Forwarded-For` rather than every Pangolin visitor as one address.
#
# ### Egress containment
# Pangolin decides which targets Newt proxies to (and which Gerbil endpoint it tunnels to), so
# without a limit whoever controls the Pangolin server could reach any LAN host:port — or use this
# homelab as a relay to anywhere on the internet — through Newt's normal NAT'd podman egress. Each
# instance's `newt-<instance>-egress` nftables table below is default-deny, allowing its bridge
# exactly:
# - its own gateway on tcp/443 (Caddy, i.e. only Caddy-fronted services) and udp/53 (aardvark-dns,
#   for any other lookup — Newt's `DNS` setting is only used inside the tunnel)
# - `pangolin.ip` (the Pangolin VPS's IPv4, public or private) on tcp/443 (API + websocket) and
#   udp/51820,21820 (Gerbil's WireGuard and relay/hole-punch ports)
# Everything else is rejected (TCP reset / ICMP admin-prohibited, so it fails fast) — other host
# ports, the host's LAN IP, other containers' published ports, the rest of the LAN and the rest of
# the internet. The VPS address is pinned rather than
# resolved from `pangolin.url` at runtime, so a changed DNS record or a server-pushed endpoint can't
# widen it; if the VPS ever changes IP, update `host.services.oci.newt.instances.<instance>.pangolin.ip`.
# It's a single address because one Newt is one site connection to one Pangolin server (one url,
# one id/secret), and Gerbil's `base_endpoint` is that same server's dashboard domain - so instance
# A's container can never reach instance B's server, or vice versa.
# The endpoint's hostname is pinned to that same address in the container's /etc/hosts
# (`--add-host`), which Newt's resolver checks before DNS, so name and egress rule can't disagree.
# Otherwise the name resolves through aardvark-dns to the host's upstream resolver: on a host that
# doesn't use the LAN AdGuard (whose rewrite points it at a local test server) the name never
# resolves at all, and where AdGuard is used its `*.<domain>` split-horizon wildcard would answer
# with the homelab's own Caddy - either way Newt silently never connects (hosts/vm-homelab ->
# hosts/vm-vps1, 2026-10-06). It also means a spoofed DNS answer can't steer Newt's dials, and TLS
# still validates against the name. Covers the WireGuard dial too, since Gerbil's `base_endpoint`
# is that same hostname.
# It hooks prerouting at mangle priority, ahead of netavark's DNAT (-100), so it judges the address
# Newt actually dialed — a published port reached via the host's IP is caught before it's rewritten
# to a container. `host.containers.internal` is pinned to that same gateway (rather than podman's
# `host-gateway` lookup) so the target in Pangolin always matches what the rule allows.
# Apps not fronted by Caddy are therefore unreachable through Newt by design — front them with Caddy.
# Debug rejects with: sudo nft monitor trace (after adding `meta nftrace set 1` to the egress chain)
# --------------------------------------------------------------------------------------------------
{ config, lib, f, ... }: with lib.types;
let
  cfg = config.services.oci.newt;

  # Only enabled instances get a container, network, secret and egress rule
  enabled = lib.filterAttrs (_: inst: inst.enable) cfg.instances;

  # Container, network, unit and secret-template name for an instance e.g. "newt-a"
  contName = name: "${cfg.name}-${name}";

  # Netavark gives a `--subnet` network the first host address as its gateway (see createContNetwork)
  gatewayOf = inst: f.hostInSubnet (toString inst.subnet) 1;

  # Bare hostname of `pangolin.url` (scheme, path and port stripped), pinned to `pangolin.ip`
  pangolinHostOf = inst: builtins.head (lib.splitString ":"
    (builtins.head (lib.splitString "/" (lib.last (lib.splitString "://" inst.pangolin.url)))));

  # Bridge names of the enabled instances that collide after f.contBridge's 15-character cut
  bridges = map (name: f.contBridge (contName name)) (lib.attrNames enabled);
  duplicateBridges = lib.unique (lib.filter (b: lib.count (x: x == b) bridges > 1) bridges);

  # One site connection to one Pangolin server
  instanceOpts = { name, ... }: {
    options = {
      # On by default: defining an instance in args is what deploys it, so this only needs
      # setting to turn one off without deleting its connection details
      enable = lib.mkOption {
        description = "Run Newt site connection '${name}'";
        type = types.bool;
        default = true;
      };

      # The one Pangolin server this site connects to — one Newt is one site connection (one URL,
      # one id/secret), and Gerbil's `base_endpoint` is that same server's dashboard domain
      pangolin = {
        url = lib.mkOption {
          description = ''
            Pangolin server base URL this site connects to — the dashboard's "Endpoint", passed to
            Newt as PANGOLIN_ENDPOINT. Forwarded by modules/default.nix from
            `host.services.oci.newt.instances.${name}.pangolin.url`.
          '';
          type = types.str;
          default = "";
          example = "https://pangolin.example.com";
        };

        ip = lib.mkOption {
          description = ''
            IPv4 address of the Pangolin server — the only internet/LAN destination this
            instance's egress rule allows, and what `pangolin.url`'s hostname (and Gerbil's
            `base_endpoint`) is pinned to inside the container, bypassing DNS. The public VPS IP in
            production, or its LAN IP for a local test server like hosts/vm-vps1. Forwarded by
            modules/default.nix from `host.services.oci.newt.instances.${name}.pangolin.ip`,
            keeping it out of tracked files.
          '';
          type = types.nullOr types.str;
          default = null;
          example = "203.1.138.10";
        };
      };

      id = lib.mkOption {
        description = ''
          Newt Site ID issued by Pangolin when the Site is created. Forwarded by
          modules/default.nix from `host.services.oci.newt.instances.${name}.id`.
        '';
        type = types.str;
        default = "";
      };

      # Same pinning rationale as the shared `subnet`/`ip` in modules/types/service.nix, but per
      # instance since each runs on its own podman network
      subnet = lib.mkOption {
        description = "Fixed /24 CIDR (e.g. `10.89.120.0/24`) for this instance's isolated podman network";
        type = types.nullOr types.str;
        default = null;
      };

      ip = lib.mkOption {
        description = "Fixed IP address (within `subnet`) for this instance's container";
        type = types.nullOr types.str;
        default = null;
      };
    };
  };

  # Everything one enabled instance deploys
  mkInstance = name: inst: let
    cont = contName name;
    gateway = gatewayOf inst;
    secretKey = "newt/${name}/clientSecret";
  in {
    assertions = f.ociAsserts (cfg // { name = cont; inherit (inst) subnet ip; }) ++ [
      { assertion = inst.pangolin.url != "";
        message = "services.oci.newt.instances.${name} requires 'pangolin.url' set (host.services.oci.newt.instances.${name}.pangolin.url) — the Pangolin dashboard's base URL"; }
      { assertion = inst.id != "";
        message = "services.oci.newt.instances.${name} requires 'id' set (host.services.oci.newt.instances.${name}.id) — from the Pangolin Site's Newt credentials"; }
      { assertion = lib.hasSuffix ".0/24" (toString inst.subnet);
        message = "services.oci.newt.instances.${name} requires a /24 'subnet' ending in .0 — its egress rule derives the gateway from it"; }
      # A literal IPv4 only — nft would resolve a hostname once at ruleset load, silently pinning
      # whatever it pointed at then
      { assertion = inst.pangolin.ip != null
          && builtins.match "[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}" inst.pangolin.ip != null;
        message = "services.oci.newt.instances.${name} requires 'pangolin.ip' set to an IPv4 address (host.services.oci.newt.instances.${name}.pangolin.ip) — the Pangolin server, the only destination its egress rule allows"; }
    ];

    # Combine the sensitive secret with the non-secret url/id into one env file for the
    # container, decrypted at activation to sops-nix's default path
    # (config.secret.templates."newt-<instance>".path, normally /run/secrets/rendered/newt-<instance>),
    # never touching the Nix store or the unit's command line the way a plain `environment` entry
    # would. It is still visible in `podman inspect` (env-file values land in Config.Env), which
    # only root - or anyone with podman API access - can run.
    secret.templates."${cont}" = {
      filemode = "0400";
      content = ''
        PANGOLIN_ENDPOINT=${inst.pangolin.url}
        NEWT_ID=${inst.id}
        NEWT_SECRET=${config.secret.ref.${secretKey}}
        LOG_LEVEL=${cfg.logLevel}
      '';
      secrets.${secretKey}.sopsFile = cfg.sopsFile;
      # The container gets these as environment variables at start, so a rotated NEWT_SECRET
      # needs the container restarted to take effect
      restartUnits = [ "podman-${cont}.service" ];
    };

    # Generate the "podman-newt-<instance>" service unit for the container
    # - cfg.port is unused here (Newt publishes no ports) — kept only because it's part of the
    #   shared service.nix type this module reuses for name/tag/user consistency
    virtualisation.oci-containers.containers."${cont}" = {
      image = "docker.io/fosrl/newt:${cfg.tag}";
      autoStart = true;
      hostname = cont;
      user = "${toString cfg.user.uid}:${toString cfg.user.gid}";
      networks = [ (f.contNetwork cont cont) ];  # Isolated network, named veth
      environment = {
        # CONFIG_FILE is Newt's documented override (see resolveConfigFilePath in fosrl/newt) —
        # point it at the writable /tmp tmpfs mounted below instead. Directly in /tmp: Newt's
        # saveConfig is a bare os.WriteFile that never creates parent directories, so a
        # subdirectory here fails every save ("open ...: no such file or directory").
        CONFIG_FILE = "/tmp/newt-config.json";
        # Off to limit what the Pangolin server can open — see notes above
        DISABLE_CLIENTS = lib.boolToString (!cfg.allowClients);
        DISABLE_SSH = "true";
        # NO_CLOUD is deliberately NOT set. Despite the name, Pangolin's Enterprise build answers a
        # `noCloud` newt with no `gerbil`-type exit nodes at all - including a self-hosted Gerbil
        # (server/private/lib/exitNodes/exitNodes.ts) - so Newt logs "No exit nodes provided" and
        # never brings its tunnel up (hosts/vm-homelab -> hosts/vm-vps1 on ee-1.21.1, 2026-10-06).
        # Cloud failover is already impossible regardless: the egress rule only allows
        # `pangolin.ip`.
        # Present only while the tunnel is up — read by the healthcheck below
        HEALTH_FILE = "/tmp/newt-healthy";
      } // lib.optionalAttrs cfg.allowClients {
        DNS = gateway;   # In-tunnel DNS via aardvark-dns - the only resolver egress allows
      };
      environmentFiles = [ config.secret.templates."${cont}".path ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
      ];
      extraOptions = [
        "--add-host=host.containers.internal:${gateway}"  # Caddy via the gateway — see notes above
        "--add-host=${pangolinHostOf inst}:${toString inst.pangolin.ip}" # Endpoint pinned to the egress rule's IP
        "--ip=${inst.ip}"
        # Report-only tunnel health (the default --health-on-failure=none) — see notes above
        ''--health-cmd=["CMD","test","-f","/tmp/newt-healthy"]''
        "--health-interval=30s"
        "--health-start-period=60s"
      ] ++ lib.optionals cfg.capDropAll [ "--cap-drop=ALL" ]
        ++ lib.optionals cfg.noNewPrivileges [ "--security-opt=no-new-privileges" ]
        ++ lib.optionals cfg.readOnlyRootfs [ "--read-only" "--tmpfs=/tmp" ];
    };

    # Newt is outbound-only (dials out to Pangolin/Gerbil) — nothing to publish, so no
    # networking.firewall rule is added for it. DNS to aardvark-dns on its gateway is already allowed
    # by podman.nix's `iifname "podman*"` rule, which its bridge (`f.contBridge`) falls under.

    # Egress containment — see "Egress containment" in the notes above
    networking.nftables.tables."${cont}-egress" = {
      family = "inet";
      content = ''
        chain prerouting {
          type filter hook prerouting priority mangle; policy accept;
          iifname "${f.contBridge cont}" jump egress
        }

        chain egress {
          meta nfproto != ipv4 drop
          ct state established,related accept

          # Caddy and aardvark-dns on the bridge gateway
          ip daddr ${gateway} tcp dport 443 accept
          ip daddr ${gateway} udp dport 53 accept

          # Pangolin: API/websocket and Gerbil's WireGuard/relay ports
          ip daddr ${toString inst.pangolin.ip} tcp dport 443 accept
          ip daddr ${toString inst.pangolin.ip} udp dport { 51820, 21820 } accept

          # Everything else: the host's other ports, the LAN, and the rest of the internet.
          # Rejected rather than dropped so a blocked dial fails immediately instead of waiting out
          # its timeout (e.g. Newt's startup update check to api.fossorial.io, which has no off
          # switch and otherwise stalls startup 10s) - nothing to hide from our own container.
          meta l4proto tcp reject with tcp reset
          reject with icmpx admin-prohibited
        }
      '';
    };

    # Create podman network and extend service to use it
    systemd.services."podman-network-${cont}" = f.createContNetwork { name = cont; subnet = inst.subnet; };
    # extendContService runs the unit from /var/lib/<container>, but every instance shares the one
    # Newt user whose home (/var/lib/<user>) is the only dir created - point it there instead, or
    # systemd fails the start with CHDIR. Newt writes nothing outside its /tmp tmpfs anyway.
    systemd.services."podman-${cont}" = lib.recursiveUpdate (f.extendContService { name = cont; }) {
      serviceConfig.WorkingDirectory = "/var/lib/${cfg.user.name}";
    };
  };

  # Every enabled instance's config, and the merge of one option path across all of them
  perInstance = lib.mapAttrsToList mkInstance enabled;
  collect = path: lib.mkMerge (map (lib.getAttrFromPath path) perInstance);

in
{
  # Fully user-space WireGuard — no NET_ADMIN/tun needed, and Newt is stateless with nothing
  # written outside its writable /tmp tmpfs — so it's a safe candidate for the full hardening
  # baseline by default. The shared `subnet`/`ip` are replaced by per-instance ones, and `caddy`/
  # `subdomain` don't apply to an outbound-only connector.
  options.services.oci.newt = (removeAttrs (import ../../types/service.nix {
    inherit lib;
    defaults = {
      name = "newt";
      capDropAll = true;
      noNewPrivileges = true;
      readOnlyRootfs = true;
    };
  }) [ "subnet" "ip" "caddy" "subdomain" ]) // {
    instances = lib.mkOption {
      description = ''
        Pangolin site connections, one container each, keyed by a short instance name (3
        characters or fewer, see the notes above). Each runs unless its `enable` is set false.
        Connection details are forwarded by modules/default.nix from
        `host.services.oci.newt.instances.<instance>.*`.
      '';
      type = types.attrsOf (types.submodule instanceOpts);
      default = { };
    };

    allowClients = lib.mkOption {
      description = ''
        Let Pangolin clients reach this site's private resources through Newt (clears
        DISABLE_CLIENTS) - see "Private resources" above. Set false for public resources only.
      '';
      type = types.bool;
      default = true;
    };

    logLevel = lib.mkOption {
      type = types.enum [ "DEBUG" "INFO" "WARN" "ERROR" ];
      default = "INFO";
      description = "Newt log verbosity, shared by every instance.";
    };
  };

  # Per-instance pieces are merged option by option rather than as one top-level `mkMerge` list:
  # the list depends on `instances`, and the module system must know this module's top-level
  # config keys before it can evaluate any option, so a config-dependent list there recurses.
  config = lib.mkIf (cfg.enable && enabled != { }) {
    # Have services.native.alerts check this image for new upstream releases
    services.native.alerts.imageUpdates.images.${cfg.name} = { tag = cfg.tag; repo = "fosrl/newt"; };

    assertions = [
      { assertion = cfg.sopsFile != null;
        message = "services.oci.newt requires 'sopsFile' — normally forwarded from 'host.sopsFile'"; }
      { assertion = config.networking.nftables.enable;
        message = "services.oci.newt requires networking.nftables.enable — its egress containment is nftables-only"; }
      { assertion = duplicateBridges == [ ];
        message = "services.oci.newt: instances share a bridge name after f.contBridge's 15-character truncation: ${lib.concatStringsSep ", " duplicateBridges} — shorten the instance names"; }
    ] ++ lib.concatMap (x: x.assertions) perInstance;

    virtualization.podman.enable = true;
    users.users.${cfg.user.name} = f.createUser cfg.user;
    users.groups.${cfg.user.group} = f.createGroup cfg.user;

    secret.templates = collect [ "secret" "templates" ];
    virtualisation.oci-containers.containers = collect [ "virtualisation" "oci-containers" "containers" ];
    networking.nftables.tables = collect [ "networking" "nftables" "tables" ];
    systemd.services = collect [ "systemd" "services" ];
  };
}
