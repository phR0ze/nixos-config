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
# ### Deployment Details
# - Outbound-only: Newt registers with Pangolin over HTTPS/WebSocket and tunnels over UDP to Gerbil.
#   No inbound ports are published on this host for this service, so no firewall rule is needed either.
# - Fully user-space WireGuard — no Linux capabilities, no `/dev/net/tun`, so the container runs
#   `--cap-drop=ALL`, non-root, and (by default) with a read-only rootfs.
# - `pangolin.url`/`id` identify *which* site connects, but grant nothing without the secret below.
#   They come from `host.services.oci.newt.*` in `args.enc.yaml`, forwarded by modules/default.nix.
# - Get the Endpoint/ID/Secret from the Pangolin dashboard: `Network > Sites > + Add Site > Newt Site
# - Get status with:
#   sudo systemctl status podman-newt
# - Tunnel health: Newt maintains HEALTH_FILE while its WireGuard tunnel to Gerbil is up, which the
#   podman healthcheck below reports — `podman healthcheck run newt` or the STATUS column of
#   `sudo podman ps`. Report-only: Newt reconnects on its own, so an unhealthy state never kills it.
# - Newt's client tunnels (DISABLE_CLIENTS) and SSH auth daemon (DISABLE_SSH) are both turned off —
#   neither is used here, and each would otherwise let the Pangolin server open more paths into the
#   homelab than the Resources defined for this site.
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
# Caddy sees all of this traffic arriving from Newt's fixed container `ip` (host-local, so it's never
# SNAT'd), so modules/default.nix adds that IP to Caddy's `trustedProxies` whenever both are enabled —
# backends (e.g. Vaultwarden's login rate limiting) then see real client IPs from Traefik's
# `X-Forwarded-For` rather than every Pangolin visitor as one address.
#
# ### Egress containment
# Pangolin decides which targets Newt proxies to (and which Gerbil endpoint it tunnels to), so
# without a limit whoever controls the Pangolin server could reach any LAN host:port — or use this
# homelab as a relay to anywhere on the internet — through Newt's normal NAT'd podman egress. The
# `newt-egress` nftables table below is default-deny, allowing Newt's bridge exactly:
# - its own gateway on tcp/443 (Caddy, i.e. only Caddy-fronted services) and udp/53 (aardvark-dns,
#   for any other lookup — Newt's `DNS` setting is only used inside the tunnel)
# - `pangolin.ip` (the Pangolin VPS's IPv4, public or private) on tcp/443 (API + websocket) and
#   udp/51820,21820 (Gerbil's WireGuard and relay/hole-punch ports)
# Everything else is rejected (TCP reset / ICMP admin-prohibited, so it fails fast) — other host
# ports, the host's LAN IP, other containers' published ports, the rest of the LAN and the rest of
# the internet. The VPS address is pinned rather than
# resolved from `pangolin.url` at runtime, so a changed DNS record or a server-pushed endpoint can't
# widen it; if the VPS ever changes IP, update `host.services.oci.newt.pangolin.ip`. It's a single
# address because one Newt is one site connection to one Pangolin server (one url, one id/secret),
# and Gerbil's `base_endpoint` is that same server's dashboard domain.
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

  # Netavark gives a `--subnet` network the first host address as its gateway (see createContNetwork)
  gateway = f.hostInSubnet (toString cfg.subnet) 1;

  # Bare hostname of `pangolin.url` (scheme, path and port stripped), pinned to `pangolin.ip`
  pangolinHost = builtins.head (lib.splitString ":"
    (builtins.head (lib.splitString "/" (lib.last (lib.splitString "://" cfg.pangolin.url)))));

in
{
  # Fully user-space WireGuard — no NET_ADMIN/tun needed, and Newt is stateless with nothing
  # written outside its writable /tmp tmpfs — so it's a safe candidate for the full hardening
  # baseline by default.
  options.services.oci.newt = (import ../../types/service.nix {
    inherit lib;
    defaults = {
      name = "newt";
      capDropAll = true;
      noNewPrivileges = true;
      readOnlyRootfs = true;
    };
  }) // {
    # The one Pangolin server this site connects to — one Newt is one site connection (one URL, one
    # id/secret), and Gerbil's `base_endpoint` is that same server's dashboard domain
    pangolin = {
      url = lib.mkOption {
        description = ''
          Pangolin server base URL this site connects to — the dashboard's "Endpoint", passed to
          Newt as PANGOLIN_ENDPOINT. Forwarded by modules/default.nix from
          `host.services.oci.newt.pangolin.url`.
        '';
        type = types.str;
        default = "";
        example = "https://pangolin.example.com";
      };

      ip = lib.mkOption {
        description = ''
          IPv4 address of the Pangolin server — the only internet/LAN destination Newt's egress
          rule allows, and what `pangolin.url`'s hostname (and Gerbil's `base_endpoint`) is pinned
          to inside the container, bypassing DNS. The public VPS IP in production, or
          its LAN IP for a local test server like hosts/vm-vps1. Forwarded by modules/default.nix
          from `host.services.oci.newt.pangolin.ip`, keeping it out of tracked files.
        '';
        type = types.nullOr types.str;
        default = null;
        example = "203.1.138.10";
      };
    };

    id = lib.mkOption {
      description = ''
        Newt Site ID issued by Pangolin when the Site is created. Forwarded by
        modules/default.nix from `host.services.oci.newt.id`.
      '';
      type = types.str;
      default = "";
    };

    logLevel = lib.mkOption {
      type = types.enum [ "DEBUG" "INFO" "WARN" "ERROR" ];
      default = "INFO";
      description = "Newt log verbosity.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Have services.native.alerts check this image for new upstream releases
    services.native.alerts.imageUpdates.images.${cfg.name} = { tag = cfg.tag; repo = "fosrl/newt"; };

    assertions = f.ociAsserts cfg ++ [
      { assertion = cfg.pangolin.url != "";
        message = "services.oci.newt requires 'pangolin.url' set (host.services.oci.newt.pangolin.url) — the Pangolin dashboard's base URL"; }
      { assertion = cfg.id != "";
        message = "services.oci.newt requires 'id' set (host.services.oci.newt.id) — from the Pangolin Site's Newt credentials"; }
      { assertion = cfg.sopsFile != null;
        message = "services.oci.newt requires 'sopsFile' — normally forwarded from 'host.sopsFile'"; }
      { assertion = lib.hasSuffix ".0/24" (toString cfg.subnet);
        message = "services.oci.newt requires a /24 'subnet' ending in .0 — its egress rule derives the gateway from it"; }
      # A literal IPv4 only — nft would resolve a hostname once at ruleset load, silently pinning
      # whatever it pointed at then
      { assertion = cfg.pangolin.ip != null
          && builtins.match "[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}" cfg.pangolin.ip != null;
        message = "services.oci.newt requires 'pangolin.ip' set to an IPv4 address (host.services.oci.newt.pangolin.ip) — the Pangolin server, the only destination its egress rule allows"; }
      { assertion = config.networking.nftables.enable;
        message = "services.oci.newt requires networking.nftables.enable — its egress containment is nftables-only"; }
    ];

    virtualization.podman.enable = true;
    users.users.${cfg.user.name} = f.createUser cfg.user;
    users.groups.${cfg.user.group} = f.createGroup cfg.user;

    # Combine the sensitive secret with the non-secret url/id into one env file for the
    # container, decrypted at activation to sops-nix's default path
    # (config.secret.templates."newt-<name>".path, normally /run/secrets/rendered/newt-<name>),
    # never touching the Nix store or the unit's command line the way a plain `environment` entry
    # would. It is still visible in `podman inspect` (env-file values land in Config.Env), which
    # only root - or anyone with podman API access - can run.
    secret.templates."newt-${cfg.name}" = {
      filemode = "0400";
      content = ''
        PANGOLIN_ENDPOINT=${cfg.pangolin.url}
        NEWT_ID=${cfg.id}
        NEWT_SECRET=${config.secret.ref."newt/clientSecret"}
        LOG_LEVEL=${cfg.logLevel}
      '';
      secrets."newt/clientSecret".sopsFile = cfg.sopsFile;
      # The container gets these as environment variables at start, so a rotated NEWT_SECRET
      # needs the container restarted to take effect
      restartUnits = [ "podman-${cfg.name}.service" ];
    };

    # Generate the "podman-newt" service unit for the container
    # - cfg.port is unused here (Newt publishes no ports) — kept only because it's part of the
    #   shared service.nix type this module reuses for name/tag/user consistency
    virtualisation.oci-containers.containers."${cfg.name}" = {
      image = "docker.io/fosrl/newt:${cfg.tag}";
      autoStart = true;
      hostname = "${cfg.name}";
      user = "${toString cfg.user.uid}:${toString cfg.user.gid}";
      networks = [ (f.contNetwork cfg.name cfg.name) ];  # Isolated network, named veth
      environment = {
        # CONFIG_FILE is Newt's documented override (see resolveConfigFilePath in fosrl/newt) —
        # point it at the writable /tmp tmpfs mounted below instead. Directly in /tmp: Newt's
        # saveConfig is a bare os.WriteFile that never creates parent directories, so a
        # subdirectory here fails every save ("open ...: no such file or directory").
        CONFIG_FILE = "/tmp/newt-config.json";
        # Unused features, off to limit what the Pangolin server can open — see notes above
        DISABLE_CLIENTS = "true";
        DISABLE_SSH = "true";
        # NO_CLOUD is deliberately NOT set. Despite the name, Pangolin's Enterprise build answers a
        # `noCloud` newt with no `gerbil`-type exit nodes at all - including a self-hosted Gerbil
        # (server/private/lib/exitNodes/exitNodes.ts) - so Newt logs "No exit nodes provided" and
        # never brings its tunnel up (hosts/vm-homelab -> hosts/vm-vps1 on ee-1.21.1, 2026-10-06).
        # Cloud failover is already impossible regardless: the egress rule only allows
        # `pangolin.ip`.
        # Present only while the tunnel is up — read by the healthcheck below
        HEALTH_FILE = "/tmp/newt-healthy";
      };
      environmentFiles = [ config.secret.templates."newt-${cfg.name}".path ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
      ];
      extraOptions = [
        "--add-host=host.containers.internal:${gateway}"  # Caddy via the gateway — see notes above
        "--add-host=${pangolinHost}:${toString cfg.pangolin.ip}" # Endpoint pinned to the egress rule's IP
        "--ip=${cfg.ip}"
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
    networking.nftables.tables."${cfg.name}-egress" = {
      family = "inet";
      content = ''
        chain prerouting {
          type filter hook prerouting priority mangle; policy accept;
          iifname "${f.contBridge cfg.name}" jump egress
        }

        chain egress {
          meta nfproto != ipv4 drop
          ct state established,related accept

          # Caddy and aardvark-dns on the bridge gateway
          ip daddr ${gateway} tcp dport 443 accept
          ip daddr ${gateway} udp dport 53 accept

          # Pangolin: API/websocket and Gerbil's WireGuard/relay ports
          ip daddr ${toString cfg.pangolin.ip} tcp dport 443 accept
          ip daddr ${toString cfg.pangolin.ip} udp dport { 51820, 21820 } accept

          # Everything else: the host's other ports, the LAN, and the rest of the internet.
          # Rejected rather than dropped so a blocked dial fails immediately instead of waiting out
          # its timeout (e.g. Newt's startup update check to api.fossorial.io, which has no off
          # switch and otherwise stalls startup 10s) - nothing to hide from our own container.
          meta l4proto tcp reject with tcp reset
          reject with icmpx admin-prohibited
        }
      '';
    };

    # Newt dials out to Pangolin as soon as it starts, so start it once the network is up, after
    # boot (see devices.network.onlineServices)
    devices.network.onlineServices = [ "podman-${cfg.name}" ];

    # Create podman network and extend service to use it
    systemd.services."podman-network-${cfg.name}" = f.createContNetwork { name = cfg.name; subnet = cfg.subnet; };
    systemd.services."podman-${cfg.name}" = f.extendContService { name = cfg.name; };
  };
}
