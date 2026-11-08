# Ghost configuration
# - https://ghost.org/docs/
# - https://hub.docker.com/_/ghost
# - https://github.com/TryGhost/ghost-docker (upstream's own compose, the reference for this stack)
#
# ### Description
# Ghost is a Node.js publishing platform for blogs and newsletters: a fast themed public site, an
# editor/admin app, and built-in memberships with email sign-up, paid subscriptions and newsletters.
#
# ### Deployment Details
# Two containers on one isolated podman network `<name>` (`subnet`), neither touching the host's
# shared postgres:
# - `<name>-db`: MySQL 8 at `hostInSubnet subnet 3` - the only production database Ghost supports
#   (no MariaDB/Postgres; SQLite is dev-only). Not published, only Ghost can reach it. Pinned by
#   `dbTag` to the major Ghost's own compose tests against, and tuned for a small footprint.
# - `<name>`: Ghost at `ip`, published on `127.0.0.1:<port>` behind Caddy.
# Both run as the `user.uid` app user with every capability dropped - neither image needs root
# when started with `--user` against data dirs it already owns.
#
# - App data is persisted at /var/lib/$APP/{content,mysql}
# - Get status with: sudo systemctl status podman-ghost podman-ghost-db
# - Logs go to stdout, so: journalctl -u podman-ghost
#
# ### Deployment notes
# 1. Ghost redirects every request to its one canonical `url`, so the usual `<app>` + `<app>-vpn`
#    subdomain pair doesn't fit. Instead the public site is `<subdomain>.<zone>` and the admin app
#    is `<adminSubdomain>.<zone>` (Ghost's `admin__url`). With the two on different hosts Ghost
#    only mounts `/ghost` (the admin app and Admin API) on the admin host, and redirects
#    `<subdomain>.<zone>/ghost` there.
# 2. Pangolin (Newt's `pangolin.resources`, see "Blueprints" in modules/services/oci/newt.nix):
#    `blog: { sso: false }` for the public site, as visitors have no account (like `photos`), and
#    `blog-admin: { public: false, private: true }` so the admin is reachable only from Pangolin
#    clients or the LAN. As with Vaultwarden note 5, a Pangolin server under another zone needs
#    `whichDomains = "all"` and that zone in `host.network.domains`.
# 3. Secrets, in this host's `secrets.enc.yaml` (`sopsFile`, forwarded from `host.sopsFile`):
#    - `ghost/dbPassword`: the `ghost` MySQL user's password. Only read by MySQL on first init of
#      an empty data dir, so changing it later means `ALTER USER` inside the DB as well
#    - `ghost/mail/{host,port,user,pass,from}`: SMTP for staff invites, password resets, member
#      magic links and new-device login codes, when `mail.enable`. Any transactional provider
#      works; bulk newsletters additionally need Mailgun, configured in Ghost's admin settings
# 4. First run: browse to `https://<adminSubdomain>.<zone>/ghost` and create the owner account
#    straight away - until then anyone who can reach the admin host can claim the site.
# 5. Not wired up: Ghost 6's Network (ActivityPub) needs the proxy to route `/.ghost/activitypub/*`
#    and `/.well-known/{webfinger,nodeinfo}` to an ActivityPub service, and Traffic Analytics needs
#    Tinybird. Neither is configured, so leave Network off under Settings in the admin app.
#
# ### Hardening
# - Containers: non-root `--user`, `--cap-drop=ALL`, `no-new-privileges`, read-only rootfs (only
#   the data volumes and tmpfs scratch dirs are writable) and memory/pids caps, so a runaway upload
#   or compromise can't starve the host's other services. `readOnlyRootfs = false` backs it out.
# - Egress (`<name>-egress` nftables table, the same shape as Newt's): MySQL may dial nothing at
#   all. Ghost may reach MySQL, aardvark-dns, Caddy on the gateway (its own URLs, pinned there with
#   `--add-host`) and the public internet (SMTP, oEmbed/bookmark previews, updates) but no
#   private/LAN range - an editor pasting a LAN URL into a bookmark card can't turn Ghost's
#   link-preview fetcher into an SSRF probe of the homelab.
# - Privacy: no Explore "phone home" (it reports the site URL, theme and post counts), no Gravatar
#   lookups (hashed staff/member emails) and no Ping-O-Matic pings on publish. The update check
#   stays on - it sends only the Ghost version and surfaces security notices in the admin.
# - Real client IPs: Caddy discards client-supplied `X-Forwarded-For` and only trusts Newt's, so
#   Ghost's built-in login/magic-link brute-force limits key on the real visitor.
# - Admin side (stored in the DB, so set in the admin app, not here): staff 2FA rides on
#   `mail.enable` (new-device codes); give staff the lowest role that works since Administrators
#   can add site-wide Code Injection (stored XSS by design); revoke unused custom integrations
#   (an Admin API key is full admin); only upload trusted themes; and set Membership → Subscription
#   access to "Nobody"/"Only people I invite" and Comments off unless they're actually wanted.
#
# ### Backup process
# `<backupDir>/ghost` gets a nightly snapshot at `backupTime` without stopping anything: a
# `mysqldump --single-transaction` of the DB to `ghost.sql`, plus an rsync of `content/` (images,
# media, files, themes, settings). Each run overwrites the last.
#
# **Trigger backup**
# sudo systemctl start backup-ghost
#
# #### Restore
# The backup share doesn't preserve ownership or modes, so content is copied with `-rlt` and the
# ownership reset afterwards, the same as homarr.
#
# 1. Stop Ghost, leaving the DB running
#    sudo systemctl stop podman-ghost
#
# 2. Load the dump into the DB
#    sudo podman exec -i ghost-db sh -c 'MYSQL_PWD="$MYSQL_PASSWORD" exec mysql -u"$MYSQL_USER" "$MYSQL_DATABASE"' < <backupDir>/ghost/ghost.sql
#
# 3. Restore the content and reset ownership to the app user (`user.uid`)
#    sudo rsync -rlt --delete <backupDir>/ghost/content/ /var/lib/ghost/content/
#    sudo chown -R ghost:ghost /var/lib/ghost/content
#
# 4. Start Ghost
#    sudo systemctl start podman-ghost
#
# ### Verify
#  curl -sI https://<subdomain>.<zone>                      # 200
#  curl -sI https://<subdomain>.<zone>/ghost/               # 301 -> <adminSubdomain>
#  curl -s https://<adminSubdomain>.<zone>/ghost/api/admin/site/
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.services.oci.ghost;
  image = "docker.io/library/ghost";
  dbImage = "docker.io/library/mysql";
  dbName = "${cfg.name}-db";
  dbIp = f.hostInSubnet cfg.subnet 3;
  defaultUrl = sub: if !cfg.caddy || cfg.domains == [ ] || sub == null then null
    else "https://${sub}.${lib.head cfg.domains}";

  gateway = f.hostInSubnet cfg.subnet 1;

  # Ghost's own hostnames, pinned to the gateway so its requests to itself (e.g. a bookmark card
  # of one of its own posts) reach Caddy there instead of the LAN IP egress rejects
  selfHosts = lib.optionals cfg.caddy (map (u: lib.head (lib.splitString "/" (lib.removePrefix "https://" u)))
    (lib.filter (u: u != null && lib.hasPrefix "https://" u) [ cfg.url cfg.adminUrl ]));

  # Shared by both containers: rootless inside, no capabilities, see service.nix's hardening fields.
  # A read-only rootfs gets a /tmp tmpfs for upload staging and MySQL's temp tables
  hardening = lib.optionals cfg.capDropAll [ "--cap-drop=ALL" ]
    ++ lib.optionals cfg.noNewPrivileges [ "--security-opt=no-new-privileges" ]
    ++ lib.optionals cfg.readOnlyRootfs [ "--read-only" "--tmpfs=/tmp" ]
    ++ [ "--pids-limit=512" ];
in
{
  options.services.oci.ghost = (import ../../types/service.nix {
    inherit lib; defaults = {
      name = "ghost"; caddy = true; subdomain = "blog";
      # Both images skip their root -> gosu drop when started with `--user`, so need no capability,
      # and only write to their data volumes plus the tmpfs scratch dirs added for them
      capDropAll = true; noNewPrivileges = true; readOnlyRootfs = true;
    };
  }) // {
    dbTag = lib.mkOption {
      description = ''
        MySQL image tag - an explicit version, never 'latest'. Track the major upstream's
        ghost-docker compose pins rather than the newest MySQL; a major bump needs a dump/restore.
      '';
      type = types.str;
      example = "8.0.46";
    };

    adminSubdomain = lib.mkOption {
      description = ''
        Subdomain the admin app (`/ghost`) is served at - Ghost's `admin__url`. Kept separate from
        `subdomain` so only the public site needs to be exposed publicly, see deployment note 1.
      '';
      type = types.str;
      default = "blog-admin";
    };

    url = lib.mkOption {
      description = ''
        Public URL of the site, which Ghost redirects every request to. Defaults to
        `https://<subdomain>.<primary domain>` when `caddy` is set.
      '';
      type = types.nullOr types.str;
      default = defaultUrl cfg.subdomain;
      defaultText = lib.literalExpression ''"https://''${subdomain}.''${lib.head domains}" when caddy, else null'';
      example = "https://blog.example.com";
    };

    adminUrl = lib.mkOption {
      description = ''
        URL of the admin app. Defaults to `https://<adminSubdomain>.<primary domain>` when `caddy`
        is set. `null` serves the admin from `url` instead.
      '';
      type = types.nullOr types.str;
      default = defaultUrl cfg.adminSubdomain;
      defaultText = lib.literalExpression ''"https://''${adminSubdomain}.''${lib.head domains}" when caddy, else null'';
      example = "https://blog-admin.example.com";
    };

    mail = {
      enable = lib.mkOption {
        description = ''
          Send mail over SMTP using the `ghost/mail/*` secrets, see deployment note 3. When
          `false`, staff new-device verification is turned off as well, since its login codes
          could never arrive - members and newsletters won't work until this is on.
        '';
        type = types.bool;
        default = true;
      };

      secure = lib.mkOption {
        description = "Use implicit TLS (port 465). Leave `false` for STARTTLS on 587";
        type = types.bool;
        default = false;
      };
    };

    backupDir = lib.mkOption {
      description = ''
        Parent directory to snapshot the DB and content into nightly, as `<backupDir>/<name>`,
        overwriting the previous run - see the backup process notes above. Forwarded from
        `host.backupDir` by `modules/default.nix`. Must be outside `/var/lib/<name>`. `null`
        disables backups.
      '';
      type = types.nullOr types.str;
      default = null;
      example = "/mnt/Apps/homelab";
    };

    backupTime = lib.mkOption {
      description = ''
        When the nightly `backupDir` snapshot runs, as a systemd `OnCalendar` expression. Nothing
        is stopped for the run.
      '';
      type = types.str;
      default = "23:45";
      example = "Sun 02:30";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Have services.native.alerts check Ghost for new upstream releases. MySQL publishes no
      # GitHub releases to compare against, and its pin follows upstream's compose anyway
      services.native.alerts.imageUpdates.images.${cfg.name} = { tag = cfg.tag; repo = "TryGhost/Ghost"; inherit image; };

      assertions = f.ociAsserts cfg ++ [
        { assertion = cfg.sopsFile != null;
          message = "services.oci.ghost requires 'sopsFile', normally forwarded from 'host.sopsFile'"; }
        { assertion = cfg.url != null;
          message = "services.oci.ghost requires 'url', defaulted from 'subdomain' and 'domains' when 'caddy' is set"; }
        { assertion = cfg.caddy -> cfg.subdomain != null;
          message = "services.oci.ghost: 'caddy' requires 'subdomain' to be set"; }
        { assertion = cfg.subdomain != cfg.adminSubdomain;
          message = "services.oci.ghost: 'subdomain' and 'adminSubdomain' must differ"; }
        { assertion = config.networking.nftables.enable;
          message = "services.oci.ghost requires networking.nftables.enable - its egress containment is nftables-only"; }
      ];

      virtualization.podman.enable = true;
      users.users.${cfg.user.name} = f.createUser cfg.user;
      users.groups.${cfg.user.group} = f.createGroup cfg.user;

      # Create persistent directories for application
      # - Args: type, path, mode, user, group, expiration
      # - No group specified, i.e `-` defaults to root
      # - No age specified, i.e `-` defaults to infinite
      systemd.tmpfiles.rules = [
        "d /var/lib/${cfg.name}/content 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
        "d /var/lib/${cfg.name}/mysql 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      ];

      # Decrypted at activation to sops-nix's default path (normally /run/secrets/rendered/<name>),
      # never touching the Nix store. Split per container so the DB never sees the SMTP creds.
      # Both are only read at container start, hence the restarts.
      secret.templates = lib.mkIf (cfg.sopsFile != null) {
        "${dbName}" = {
          filemode = "0400";
          content = ''
            MYSQL_PASSWORD=${config.secret.ref."ghost/dbPassword"}
          '';
          secrets."ghost/dbPassword".sopsFile = cfg.sopsFile;
          restartUnits = [ "podman-${dbName}.service" ];
        };
        "${cfg.name}" = {
          filemode = "0400";
          content = ''
            database__connection__password=${config.secret.ref."ghost/dbPassword"}
          '' + lib.optionalString cfg.mail.enable ''
            mail__from=${config.secret.ref."ghost/mail/from"}
            mail__options__host=${config.secret.ref."ghost/mail/host"}
            mail__options__port=${config.secret.ref."ghost/mail/port"}
            mail__options__auth__user=${config.secret.ref."ghost/mail/user"}
            mail__options__auth__pass=${config.secret.ref."ghost/mail/pass"}
          '';
          secrets = lib.genAttrs ([ "ghost/dbPassword" ] ++ lib.optionals cfg.mail.enable
            (map (k: "ghost/mail/${k}") [ "from" "host" "port" "user" "pass" ]))
            (_: { sopsFile = cfg.sopsFile; });
          restartUnits = [ "podman-${cfg.name}.service" ];
        };
      };

      # MySQL, reachable only on the service's own podman network
      # - MYSQL_RANDOM_ROOT_PASSWORD: nothing here needs root; the `ghost` user owns its database
      # - Tuned down from the ~450 MB a default 8.0 idles at: a blog's working set is tiny
      virtualisation.oci-containers.containers."${dbName}" = {
        user = "${toString cfg.user.uid}:${toString cfg.user.gid}";
        image = "${dbImage}:${cfg.dbTag}";
        autoStart = true;
        hostname = dbName;
        networks = [ (f.contNetwork cfg.name dbName) ];  # Isolated network, named veth
        volumes = [ "/var/lib/${cfg.name}/mysql:/var/lib/mysql:rw" ];
        environment = {
          "MYSQL_RANDOM_ROOT_PASSWORD" = "yes";
          "MYSQL_DATABASE" = "ghost";
          "MYSQL_USER" = "ghost";
        };
        environmentFiles = lib.optionals (cfg.sopsFile != null) [ config.secret.templates.${dbName}.path ];
        cmd = [
          "--innodb-buffer-pool-size=128M"
          "--performance-schema=OFF"
          "--max-connections=30"
        ];
        # Socket and pid file live in /var/run/mysqld, the one rootfs path mysqld writes to
        extraOptions = [ "--ip=${dbIp}" "--memory=768m" ] ++ hardening
          ++ lib.optionals cfg.readOnlyRootfs [ "--tmpfs=/var/run/mysqld" ];
      };

      # Generate the "podman-${cfg.name}" service unit for the container
      # Config via Ghost's nconf env overrides, `__` separating nested keys
      virtualisation.oci-containers.containers."${cfg.name}" = {
        user = "${toString cfg.user.uid}:${toString cfg.user.gid}";
        image = "${image}:${cfg.tag}";
        autoStart = true;
        hostname = cfg.name;
        networks = [ (f.contNetwork cfg.name cfg.name) ];  # Isolated network, named veth
        # Loopback-only when fronted by Caddy, otherwise published on the LAN
        ports = [ "${lib.optionalString cfg.caddy "127.0.0.1:"}${toString cfg.port}:2368" ];
        volumes = [ "/var/lib/${cfg.name}/content:/var/lib/ghost/content:rw" ];
        environment = {
          "NODE_ENV" = "production";
          "url" = cfg.url;
          "database__client" = "mysql";
          "database__connection__host" = dbIp;
          "database__connection__user" = "ghost";
          "database__connection__database" = "ghost";
          "logging__transports" = ''["stdout"]'';           # journal, not content/logs
          # Privacy, see "Hardening" above. nconf parses these to boolean `false`
          "explore__update_url" = "false";
          "explore__testimonials_url" = "false";
          "privacy__useGravatar" = "false";
          "privacy__useRpcPing" = "false";
        } // lib.optionalAttrs (cfg.adminUrl != null) {
          "admin__url" = cfg.adminUrl;
        } // (if cfg.mail.enable then {
          "mail__transport" = "SMTP";
          "mail__options__secure" = lib.boolToString cfg.mail.secure;
        } else {
          "security__staffDeviceVerification" = "false";    # its login codes could never arrive
        });
        environmentFiles = lib.optionals (cfg.sopsFile != null) [ config.secret.templates.${cfg.name}.path ];
        # Headroom for sharp resizing large image uploads
        extraOptions = [ "--ip=${cfg.ip}" "--memory=1536m" ] ++ hardening
          ++ map (h: "--add-host=${h}:${gateway}") selfHosts;
      };

      # Create podman network and extend both services to use it. Ghost also requires the DB: on
      # a fresh data dir MySQL takes a while to initialise and Ghost exits until it answers, which
      # Restart=always rides out
      systemd.services."podman-network-${cfg.name}" = f.createContNetwork { name = cfg.name; subnet = cfg.subnet; };
      systemd.services."podman-${dbName}" = f.extendContService { name = cfg.name; };
      systemd.services."podman-${cfg.name}" = f.extendContService { name = cfg.name; deps = [ "db" ]; };

      networking.firewall.allowedTCPPorts = lib.optional (!cfg.caddy) cfg.port;

      # See "Hardening" above. Hooks prerouting at mangle priority like Newt's, before netavark's
      # DNAT, so it judges the address actually dialed. Replies to Caddy's inbound connections
      # are `established`; br_netfilter also puts Ghost -> MySQL on the bridge through here
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

            # Ghost -> MySQL, and Caddy (its own URLs) and aardvark-dns on the bridge gateway
            ip saddr ${cfg.ip} ip daddr ${dbIp} tcp dport 3306 accept
            ip saddr ${cfg.ip} ip daddr ${gateway} tcp dport 443 accept
            ip saddr ${cfg.ip} ip daddr ${gateway} meta l4proto { tcp, udp } th dport 53 accept

            # Nothing else private: LAN, host, other container networks, CGNAT, link-local
            ip daddr { 0.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 127.0.0.0/8, 169.254.0.0/16,
                       172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/3 } jump deny

            # Ghost -> public internet: SMTP, oEmbed/bookmark previews, update check
            ip saddr ${cfg.ip} accept

            # MySQL, or anything else on the bridge
            jump deny
          }

          # Reject so blocked dials fail fast instead of stalling on a timeout
          chain deny {
            meta l4proto tcp reject with tcp reset
            reject with icmpx admin-prohibited
          }
        '';
      };
    })

    # Nightly online snapshot: a consistent InnoDB dump plus the content dir, nothing stopped
    # - Runs as root to exec into the DB container; rsync -a keeps the app user's ownership
    # - The dump is written beside the last one and only replaces it once complete
    # - No wantedBy on the service itself so it never fires at boot
    (lib.mkIf (cfg.enable && cfg.backupDir != null) (let
      dataDir = "/var/lib/${cfg.name}";
      backupDir = "${cfg.backupDir}/${cfg.name}";
    in {
      assertions = [
        { assertion = !(lib.hasPrefix "${dataDir}/" "${backupDir}/");
          message = "services.oci.ghost.backupDir must be outside ${dataDir}"; }
      ];

      # Have services.native.alerts watch this backup
      services.native.alerts.enable = lib.mkDefault true;
      services.native.alerts.backup.services = [ cfg.name ];

      systemd.tmpfiles.rules = [
        "d ${backupDir} 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      ];

      systemd.services."backup-${cfg.name}" = {
        description = "Backup Ghost database and content";
        path = [ pkgs.rsync config.virtualisation.podman.package ];
        serviceConfig.Type = "oneshot";
        # --no-tablespaces: the non-root `ghost` user lacks the PROCESS privilege it would need
        script = ''
          set -euo pipefail
          podman exec ${dbName} sh -c \
            'MYSQL_PWD="$MYSQL_PASSWORD" exec mysqldump -u"$MYSQL_USER" --single-transaction --no-tablespaces "$MYSQL_DATABASE"' \
            > ${backupDir}/ghost.sql.tmp
          mv ${backupDir}/ghost.sql.tmp ${backupDir}/ghost.sql
          rsync -a --delete --exclude=/logs/ ${dataDir}/content/ ${backupDir}/content/
        '';
      };

      systemd.timers."backup-${cfg.name}" = {
        description = "Backup Ghost nightly";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.backupTime;
          Persistent = true;
        };
      };
    }))

    # Contribute a proxy entry per name on each zone it's served on (see `whichDomains`) rather
    # than requiring it be listed separately in the machine's configuration.nix. Both go to the
    # same port - Ghost routes the admin app by Host itself
    (lib.mkIf (cfg.enable && cfg.caddy) {
      services.native.caddy.enable = lib.mkDefault true;
      services.native.caddy.domains = f.caddyProxies cfg ([ { inherit (cfg) subdomain port; } ]
        ++ lib.optional (cfg.adminUrl != null) { subdomain = cfg.adminSubdomain; inherit (cfg) port; });
      assertions = [ (f.caddyDomainsAssert "oci.${cfg.name}" cfg) ];
    })
  ];
}
