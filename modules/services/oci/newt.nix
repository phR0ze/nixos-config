# Newt configuration
# - https://github.com/fosrl/newt
# - https://docs.pangolin.net/manage/sites/understanding-sites
#
# ### Description
# Newt is Pangolin's site connector: a user-space WireGuard client (netstack, no TUN device, no
# NET_ADMIN) that dials out to a Pangolin VPS and proxies traffic to the Resources defined for this
# site in the dashboard. VPS-side setup: tech-docs `networking/reverse_tunnel/pangolin/README.md`.
#
# ### Instances
# Each Pangolin server this host joins is a named entry in `instances` with its own container
# (`newt-<instance>`), podman network, egress rule and secret. Tag, user, hardening and log level are
# shared. Every instance in `args.enc.yaml` runs once the module is enabled; set `enable = false` on
# one to drop just that connection:
# ```nix
#   services.oci.newt = {
#     enable = true; user.uid = 2005; tag = "1.16.0";
#     instances.b.enable = false;   # optional
#   };
# ```
# ```yaml
# host:
#   services:
#     oci:
#       newt:
#         instances:
#           a: { id: ..., subnet: 10.89.120.0/24, ip: 10.89.120.2, pangolin: { domain: ..., ip: ... } }
# ```
# Keep instance names to 3 characters or fewer so `podman-newt-<instance>` fits the kernel's
# 15-character bridge name limit (an assertion catches collisions).
#
# ### Deployment Details
# - Outbound only (HTTPS/WebSocket to Pangolin, UDP to Gerbil): no published ports or firewall rules.
# - Runs non-root with `--cap-drop=ALL` and a read-only rootfs.
# - `pangolin.domain`/`id`/`ip` come from `host.services.oci.newt.instances.<instance>.*` in
#   `args.enc.yaml` (`pangolin.url` defaults to `https://pangolin.<domain>`); the secret is `newt/<instance>/clientSecret` in the host's secrets. Get them
#   from the dashboard: Network > Sites > + Add Site > Newt Site.
# - Status: `sudo systemctl status podman-newt-<instance>`
# - Health: Newt keeps HEALTH_FILE while its tunnel is up, shown in `sudo podman ps` STATUS. Report
#   only; Newt reconnects on its own.
# - The SSH daemon (DISABLE_SSH) is off. Client tunnels (DISABLE_CLIENTS) are on unless
#   `allowClients = false`, see "Private resources".
#
# ### Exposing services
# Newt only reaches Caddy (a native host service) through its network gateway, pinned as
# `host.containers.internal`. To expose a Caddy-fronted app, create an HTTP Resource with:
# - Target: `https`, `host.containers.internal`, port `443`.
# - TLS Server Name and Host header set to the resource's own public name. Names stay the same end
#   to end, so Caddy must serve that subdomain on the Pangolin server's zone (the app's
#   `whichDomains`, with the zone in `host.network.domains`). Without a TLS Server Name Pangolin's
#   Traefik connects without SNI (fosrl/pangolin#207) and gets Caddy's `default_sni` cert.
# Blueprints (below) set all of this up.
# Each instance's container `ip` is added to Caddy's `trustedProxies` (modules/default.nix), so
# backends see real client IPs from `X-Forwarded-For`.
#
# ### Private resources
# `allowClients` lets Pangolin clients (CLI/desktop) reach this site's private (ZTNA) resources,
# always relayed through Gerbil (udp/21820), never directly. Egress containment still applies: target
# `host.containers.internal:443`, not the host's LAN IP. `Host`-mode resources keep the client's
# SNI/Host, so Caddy routes them like a LAN client. In-tunnel DNS uses aardvark-dns on the gateway.
#
# ### Blueprints (declarative resources)
# An instance's `pangolin.resources` are rendered into a Pangolin blueprint that Newt sends to its
# server (`BLUEPRINT_FILE`) each time it connects. Pangolin then creates or updates each resource,
# keyed by its attr name (the resource's stable niceId), on this site. Dashboard edits are
# overwritten on the next connect. They live in `args.enc.yaml` with the rest of that server's
# settings:
# ```yaml
#           b:
#             pangolin:
#               domain: <pangolin base domain>
#               ip: ...
#               defaultRoles: [ "Member" ]
#               resources:
#                 vault: { }                               # public only, default roles
#                 vault-vpn: { public: false, private: true }
#                 adguard: { private: true, roles: [ "Admins" ] }  # public + private
# ```
# Every resource is named `<subdomain>.<pangolin.domain>` end to end - Caddy must serve that
# subdomain on `pangolin.domain` (asserted; see the app's `whichDomains` and `host.network.domains`).
# - Public (`public`, on by default): an HTTPS resource behind Platform SSO, proxied to Caddy on the
#   gateway (`https://host.containers.internal:443`) with the SNI and Host header set to that same
#   name.
# - Private (`private`): a Host-mode resource keyed `<key>-private`, with Newt's gateway as its
#   destination, tcp/443 only, no UDP or ICMP, aliased to that name. The client's SNI reaches Caddy
#   unchanged.
# - Roles are `roles` or else `pangolin.defaultRoles`. Pangolin *creates* any role it
#   doesn't know (a typo silently becomes a new empty role). `users` are usernames or emails, and
#   an unknown one fails the whole blueprint.
# - Failures are only logged by Newt: `journalctl -u podman-newt-<instance> | rg -i blueprint`
#   ("Blueprint application failed: ..."). Success is logged at DEBUG only.
# - Removing a resource from `pangolin.resources` does **not** delete it from Pangolin (ee-1.24.0 never
#   deletes resources from a blueprint). Delete it in the dashboard, or set `enabled = false`.
# - Migrating a dashboard-made resource: its random niceId won't match the key, and its domain
#   clashes with the new one, so delete it in the dashboard right before deploying.
#
# ### Egress containment
# The Pangolin server chooses Newt's targets, so unrestricted it could reach any LAN host or use this
# homelab as a relay. Each instance's default-deny `newt-<instance>-egress` nftables table allows only:
# - gateway tcp/443 (Caddy) and udp/53 (aardvark-dns)
# - `pangolin.ip` tcp/443 (API/websocket) and udp/51820,21820 (Gerbil WireGuard/relay)
# Everything else is rejected so blocked dials fail fast. Notes:
# - `pangolin.ip` is pinned rather than resolved, so DNS changes or server-pushed endpoints can't
#   widen it. Update it if the VPS IP changes.
# - The endpoint hostname is pinned to `pangolin.ip` via `--add-host`, so name and rule always agree.
#   Via DNS it either fails to resolve or hits AdGuard's `*.<domain>` wildcard and lands on local
#   Caddy (hosts/vm-homelab -> hosts/vm-vps1, 2026-10-06). TLS still validates against the name.
# - Hooks prerouting at mangle priority, before netavark's DNAT, so it judges the address Newt
#   actually dialed.
# - Debug: add `meta nftrace set 1` to the egress chain, then `sudo nft monitor trace`.
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.services.oci.newt;
  caddy = config.services.native.caddy;

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

  # Caddy zones a subdomain is served on
  caddyZonesOf = sub: map (zone: zone.name)
    (lib.filter (zone: lib.any (p: p.subdomain == sub) zone.proxies) (lib.attrValues caddy.domains));

  # One Pangolin resource, keyed by its blueprint niceId. See "Blueprints" above.
  resourceOpts = { name, ... }: {
    options = {
      name = lib.mkOption {
        description = "Display name in the Pangolin dashboard";
        type = types.str;
        default = name;
      };

      subdomain = lib.mkOption {
        description = ''
          The resource's name `<subdomain>.<pangolin.domain>`, used end to end: public `full-domain`,
          SNI and Host header to Caddy, and private alias
        '';
        type = types.str;
        default = name;
      };

      public = lib.mkOption {
        description = "Create the public HTTPS resource";
        type = types.bool;
        default = true;
      };

      private = lib.mkOption {
        description = "Create the private Host-mode resource `<key>-private`";
        type = types.bool;
        default = false;
      };

      roles = lib.mkOption {
        description = "Roles granted access; null uses `pangolin.defaultRoles`";
        type = types.nullOr (types.listOf types.str);
        default = null;
      };

      users = lib.mkOption {
        description = "Users (username or email) granted access individually";
        type = types.listOf types.str;
        default = [ ];
      };

      enabled = lib.mkOption {
        description = "Pangolin's own enable toggle - turns the resource off without deleting it";
        type = types.bool;
        default = true;
      };
    };
  };

  # One site connection to one Pangolin server
  instanceOpts = { name, config, ... }: {
    options = {
      enable = lib.mkOption {
        description = "Run Newt site connection '${name}'";
        type = types.bool;
        default = true;
      };

      id = lib.mkOption {
        description = ''
          Newt Site ID issued by Pangolin. From `host.services.oci.newt.instances.${name}.id`.
        '';
        type = types.str;
        default = "";
      };

      ip = lib.mkOption {
        description = "Fixed IP address (within `subnet`) for this instance's container";
        type = types.nullOr types.str;
        default = null;
      };

      subnet = lib.mkOption {
        description = "Fixed /24 CIDR (e.g. `10.89.120.0/24`) for this instance's isolated podman network";
        type = types.nullOr types.str;
        default = null;
      };

      # The one Pangolin server this site connects to
      pangolin = {
        ip = lib.mkOption {
          description = ''
            Pangolin server IPv4: the only external destination egress allows, and what
            `pangolin.url`'s hostname is pinned to in the container. The VPS public IP, or its LAN
            IP for a test server like hosts/vm-vps1. From
            `host.services.oci.newt.instances.${name}.pangolin.ip`.
          '';
          type = types.nullOr types.str;
          default = null;
          example = "203.1.138.10";
        };

        domain = lib.mkOption {
          description = ''
            Base domain of the Pangolin server: names this instance's `resources` and gives
            `pangolin.url` its default. From `host.services.oci.newt.instances.${name}.pangolin.domain`.
          '';
          type = types.str;
          default = "";
          example = "example.org";
        };

        url = lib.mkOption {
          description = ''
            Pangolin server base URL (the dashboard's "Endpoint"), passed as PANGOLIN_ENDPOINT.
            Defaults to `https://pangolin.<pangolin.domain>`, matching services.oci.pangolin's
            `dashboardDomain` default. Set it from
            `host.services.oci.newt.instances.${name}.pangolin.url` only for a dashboard elsewhere.
          '';
          type = types.str;
          # Empty without a domain, so the assertion below names what's missing
          default = lib.optionalString (config.pangolin.domain != "") "https://pangolin.${config.pangolin.domain}";
          defaultText = lib.literalExpression ''"https://pangolin.''${pangolin.domain}"'';
          example = "https://pangolin.example.com";
        };

        defaultRoles = lib.mkOption {
          description = "Roles granted access to each of `pangolin.resources` that doesn't set its own `roles`";
          type = types.listOf types.str;
          default = [ ];
        };

        resources = lib.mkOption {
          description = ''
            Pangolin resources this site serves, applied as a blueprint (see "Blueprints"). From
            `host.services.oci.newt.instances.${name}.pangolin.resources`.
          '';
          type = types.attrsOf (types.submodule resourceOpts);
          default = { };
        };
      };
    };
  };

  # Everything one enabled instance deploys
  mkInstance = name: inst: let
    cont = contName name;
    gateway = gatewayOf inst;
    secretKey = "newt/${name}/clientSecret";

    # See "Blueprints" above
    publicRes = lib.filterAttrs (_: res: res.public) inst.pangolin.resources;
    privateRes = lib.filterAttrs (_: res: res.private) inst.pangolin.resources;
    rolesOf = res: if res.roles == null then inst.pangolin.defaultRoles else res.roles;
    pangolinName = res: "${res.subdomain}.${inst.pangolin.domain}";
    blueprint = (pkgs.formats.yaml { }).generate "${cont}-blueprint.yaml" {
      # `site`/`sites` omitted: Pangolin assigns everything to the site applying the blueprint
      "public-resources" = lib.mapAttrs (_: res: {
        inherit (res) name enabled;
        mode = "http";
        "full-domain" = pangolinName res;
        # The same name to Caddy, which serves it on this zone (asserted below)
        "host-header" = pangolinName res;
        "tls-server-name" = pangolinName res;
        auth = { "sso-enabled" = true; "sso-roles" = rolesOf res; "sso-users" = res.users; };
        targets = [ { hostname = "host.containers.internal"; port = 443; method = "https"; } ];
      }) publicRes;
      "private-resources" = lib.mapAttrs' (key: res: lib.nameValuePair "${key}-private" {
        name = "${res.name} (private)";
        inherit (res) enabled users;
        mode = "host";
        destination = gateway;  # Literal IP, exactly what the egress rule allows
        alias = pangolinName res;
        "tcp-ports" = "443";
        "udp-ports" = "";       # Empty is none, unset would be all
        "disable-icmp" = true;
        roles = rolesOf res;
      }) privateRes;
    };
  in {
    assertions = f.ociAsserts (cfg // { name = cont; inherit (inst) subnet ip; }) ++ [
      { assertion = inst.pangolin.url != "";
        message = "services.oci.newt.instances.${name} requires 'pangolin.domain' (or an explicit 'pangolin.url') set (host.services.oci.newt.instances.${name}.pangolin.*) — the dashboard URL defaults to https://pangolin.<domain>"; }
      { assertion = inst.id != "";
        message = "services.oci.newt.instances.${name} requires 'id' set (host.services.oci.newt.instances.${name}.id) — from the Pangolin Site's Newt credentials"; }
      { assertion = lib.hasSuffix ".0/24" (toString inst.subnet);
        message = "services.oci.newt.instances.${name} requires a /24 'subnet' ending in .0 — its egress rule derives the gateway from it"; }
      # Literal IPv4 only: nft would resolve a hostname once at load and silently pin it
      { assertion = inst.pangolin.ip != null
          && builtins.match "[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}" inst.pangolin.ip != null;
        message = "services.oci.newt.instances.${name} requires 'pangolin.ip' set to an IPv4 address (host.services.oci.newt.instances.${name}.pangolin.ip) — the Pangolin server, the only destination its egress rule allows"; }
    ] ++ lib.optionals (inst.pangolin.resources != { }) [
      { assertion = inst.pangolin.domain != "";
        message = "services.oci.newt.instances.${name} has 'pangolin.resources' but no 'pangolin.domain' (host.services.oci.newt.instances.${name}.pangolin.domain) — the Pangolin server's base domain they're named under"; }
      # Every resource targets this host's Caddy
      { assertion = caddy.enable;
        message = "services.oci.newt.instances.${name} has 'pangolin.resources' but services.native.caddy isn't enabled — every resource targets this host's Caddy"; }
    ] ++ lib.optionals (privateRes != { }) [
      { assertion = cfg.allowClients;
        message = "services.oci.newt.instances.${name} has private resources but 'allowClients' is off, so no client could reach them"; }
    ] ++ lib.concatLists (lib.mapAttrsToList (key: res: let id = "services.oci.newt.instances.${name}.pangolin.resources.${key}"; in [
      { assertion = builtins.match "[a-z0-9]([a-z0-9-]*[a-z0-9])?" key != null;
        message = "${id}: the key is the resource's Pangolin niceId, so only lowercase letters, digits and inner hyphens"; }
      { assertion = res.public || res.private;
        message = "${id} sets neither 'public' nor 'private', so it would create nothing"; }
    ] ++ lib.optionals (caddy.enable && inst.pangolin.domain != "") [
      # The name is the same end to end, so Caddy needs that name and its certificate
      { assertion = lib.elem inst.pangolin.domain (caddyZonesOf res.subdomain);
        message = "${id}: Caddy doesn't serve '${res.subdomain}' on the instance's pangolin.domain — list that zone in host.network.domains and set the app's whichDomains = \"all\" (or name a subdomain Caddy serves there)"; }
    ]) inst.pangolin.resources);

    # Env file rendered at activation (/run/secrets/rendered/newt-<instance>), keeping the secret
    # out of the store and unit command line. Still visible to root via `podman inspect`.
    secret.templates."${cont}" = {
      filemode = "0400";
      content = ''
        PANGOLIN_ENDPOINT=${inst.pangolin.url}
        NEWT_ID=${inst.id}
        NEWT_SECRET=${config.secret.ref.${secretKey}}
        LOG_LEVEL=${cfg.logLevel}
      '';
      secrets.${secretKey}.sopsFile = cfg.sopsFile;
      # Env is read at start, so restart to pick up a rotated secret
      restartUnits = [ "podman-${cont}.service" ];
    };

    # Generate the "podman-newt-<instance>" service unit (cfg.port is unused, no ports published)
    virtualisation.oci-containers.containers."${cont}" = {
      image = "docker.io/fosrl/newt:${cfg.tag}";
      autoStart = true;
      hostname = cont;
      user = "${toString cfg.user.uid}:${toString cfg.user.gid}";
      networks = [ (f.contNetwork cont cont) ];  # Isolated network, named veth
      environment = {
        # Must be on the writable /tmp tmpfs, and directly in /tmp: Newt never creates parent dirs
        CONFIG_FILE = "/tmp/newt-config.json";
        # Limit what the Pangolin server can open, see notes above
        DISABLE_CLIENTS = lib.boolToString (!cfg.allowClients);
        DISABLE_SSH = "true";
        # NO_CLOUD is deliberately unset: Pangolin EE then sends no exit nodes, even a self-hosted
        # Gerbil, so the tunnel never comes up (ee-1.21.1). Egress already blocks cloud failover.
        # Present only while the tunnel is up, read by the healthcheck below
        HEALTH_FILE = "/tmp/newt-healthy";
      } // lib.optionalAttrs cfg.allowClients {
        DNS = gateway;   # In-tunnel DNS via aardvark-dns - the only resolver egress allows
      } // lib.optionalAttrs (inst.pangolin.resources != { }) {
        BLUEPRINT_FILE = "/etc/newt/blueprint.yaml";
      };
      environmentFiles = [ config.secret.templates."${cont}".path ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
      ] ++ lib.optionals (inst.pangolin.resources != { }) [
        # A changed blueprint is a new store path, so the unit changes and Newt restarts and resends
        "${blueprint}:/etc/newt/blueprint.yaml:ro"
      ];
      extraOptions = [
        "--add-host=host.containers.internal:${gateway}"  # Caddy via the gateway
        "--add-host=${pangolinHostOf inst}:${toString inst.pangolin.ip}" # Endpoint pinned to the egress rule's IP
        "--ip=${inst.ip}"
        # Report-only tunnel health (default --health-on-failure=none)
        ''--health-cmd=["CMD","test","-f","/tmp/newt-healthy"]''
        "--health-interval=30s"
        "--health-start-period=60s"
      ] ++ lib.optionals cfg.capDropAll [ "--cap-drop=ALL" ]
        ++ lib.optionals cfg.noNewPrivileges [ "--security-opt=no-new-privileges" ]
        ++ lib.optionals cfg.readOnlyRootfs [ "--read-only" "--tmpfs=/tmp" ];
    };

    # No firewall rule needed: outbound only, and podman.nix's `iifname "podman*"` rule already
    # allows aardvark-dns on the gateway

    # See "Egress containment" above
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

          # Reject everything else so dials fail fast (e.g. Newt's unconditional startup update
          # check to api.fossorial.io would otherwise stall 10s)
          meta l4proto tcp reject with tcp reset
          reject with icmpx admin-prohibited
        }
      '';
    };

    # Create podman network and extend service to use it
    systemd.services."podman-network-${cont}" = f.createContNetwork { name = cont; subnet = inst.subnet; };
    # Instances share one user, so only /var/lib/<user> exists, not /var/lib/<container> (CHDIR)
    systemd.services."podman-${cont}" = lib.recursiveUpdate (f.extendContService { name = cont; }) {
      serviceConfig.WorkingDirectory = "/var/lib/${cfg.user.name}";
    };
  };

  # Every enabled instance's config, and the merge of one option path across all of them
  perInstance = lib.mapAttrsToList mkInstance enabled;
  collect = path: lib.mkMerge (map (lib.getAttrFromPath path) perInstance);

in
{
  # User-space and stateless, so fully hardened by default. `subnet`/`ip` are per instance, and
  # `caddy`/`subdomain`/`domains`/`whichDomains` don't apply to an outbound-only connector.
  options.services.oci.newt = (removeAttrs (import ../../types/service.nix {
    inherit lib;
    defaults = {
      name = "newt";
      capDropAll = true;
      noNewPrivileges = true;
      readOnlyRootfs = true;
    };
  }) [ "subnet" "ip" "caddy" "subdomain" "domains" "whichDomains" ]) // {
    instances = lib.mkOption {
      description = ''
        Pangolin site connections, one container each, keyed by a name of 3 characters or fewer.
        From `host.services.oci.newt.instances.<instance>.*`.
      '';
      type = types.attrsOf (types.submodule instanceOpts);
      default = { };
    };

    allowClients = lib.mkOption {
      description = ''
        Let Pangolin clients reach this site's private resources (clears DISABLE_CLIENTS).
        Set false for public resources only.
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

  # Merged per option path: a top-level `mkMerge` over `instances` would infinitely recurse
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
