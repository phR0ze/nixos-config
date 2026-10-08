# Vaultwarden
#
# ### Description
# Vaultwarden is an unofficial, lightweight Bitwarden-compatible server implementation written in
# Rust. It's a drop-in replacement for the official Bitwarden server, compatible with all the
# official Bitwarden clients: browser extension, desktop app, mobile app and CLI.
#
# ### Deployment notes
# 1. With `caddy` (the default) Vaultwarden listens on `127.0.0.1:<port>` only and is reached
#    through Caddy's TLS at `<subdomain>.<baseDomain>` for each `subdomains` entry. With
#    `caddy = false` it listens on all interfaces and `port` is opened on the LAN instead - plain
#    HTTP, so only do this behind some other TLS-terminating proxy.
# 2. `domain` defaults to `https://<first subdomains entry>.<baseDomain>` when `caddy` is set, where
#    `baseDomain` is forwarded from `host.network.domain` by `modules/default.nix`. Set `domain`
#    explicitly to override.
# 3. To enable the `/admin` diagnostics page, set `enableAdminPanel = true` and add an admin token to
#    this host's `secrets.enc.yaml` under the `adminTokenSecretRef` key (`vaultwarden/adminToken`
#    by default). Store an Argon2 hash from `vaultwarden hash` rather than the plain token.
#    `sopsFile` is forwarded from `host.sopsFile` by `modules/default.nix`, so nothing else is
#    needed in the host's `configuration.nix`.
# 4. Point the Bitwarden client(s) at this server's `domain` and log in as normal — the first
#    account created is a regular user, not an admin. With `signupsAllowed` and
#    `invitationsAllowed` both off (the defaults) the "Create account" link is hidden and nobody
#    can register, so create the first account by briefly setting `signupsAllowed = true`, or by
#    inviting it from the `/admin` panel.
# 5. To reach this service through a Pangolin *private* (ZTNA) resource instead of a public
#    subdomain, use a `Host`-mode (raw L4 tunnel)
#    resource pointed at Newt's gateway (`host.containers.internal`) on 443 — Newt's egress rule
#    rejects this host's LAN IP — the same shared wildcard block `subdomains` above already uses. Pangolin never
#    terminates or re-originates TLS for that resource type, so the client's real SNI/Host header
#    reaches Caddy intact, same as any LAN client; no dedicated listener or port is needed. Add a
#    second entry to `subdomains` if you want the private resource to have its own distinct name
#    rather than reusing the first one — Caddy routes every entry identically.
# 6. `<backupDir>/vaultwarden` gets a nightly snapshot at `backupTime` (default 23:00) of the
#    data dir: an SQLite-safe `.backup` of the DB plus a copy of everything
#    else (attachments, `rsa_key.pem`, `config.json`, sends). Each run overwrites the last and it
#    stays on this disk, so pair it with something that keeps history off-box (e.g. restic).
#    `backupDir` is forwarded from `host.backupDir`; `null` (the default) disables backups.
#
# ### Backup process
# Backups are handled automatically and safely with the defaults to trigger a nightly run that will
# backup /var/lib/vaultwarden to <backupDir>/vaultwarden from there its up to you to then schedule
# off system backups elsewhere.
#
# #### Trigger backup
#  sudo systemctl start backup-vaultwarden
# 
# #### Manual backup steps
# 1. Stop the service
#    sudo systemctl stop vaultwarden
#
# 2. Backup the files to an alernate location
#    sudo mkdir -p /mnt/Apps/homelab/vaultwarden
#    sudo rsync -a --delete --exclude=/icon_cache/ --exclude=/tmp/ /var/lib/vaultwarden/ /mnt/Apps/homelab/vaultwarden/
#
# 3. Start the service
#    sudo systemctl start vaultwarden
#
# #### Restore
# The backup share doesn't preserve ownership or modes (everything comes back with the mount's
# forced owner and modes), so the restore copies content only (`-rlt`, leaving the live dirs'
# modes alone) and then resets ownership recursively.
#
# 1. Stop the service
#    sudo systemctl stop vaultwarden
#
# 2. Restore the data. `--delete` also clears any local `db.sqlite3-wal`/`-shm`, which must not
#    be replayed onto the restored DB (the nightly `.backup` copy has none of its own)
#    sudo rsync -rlt --delete <backupDir>/vaultwarden/ /var/lib/vaultwarden/
#
# 3. Reset ownership
#    sudo chown -R vaultwarden:vaultwarden /var/lib/vaultwarden
#
# 4. Start the service
#    sudo systemctl start vaultwarden
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.native.vaultwarden;
in
{
  options = {
    services.native.vaultwarden = {
      enable = lib.mkEnableOption "Install and configure Vaultwarden server";

      port = lib.mkOption {
        type = types.port;
        default = 8222;
        description = "Port the Vaultwarden web/API server listens on.";
      };

      baseDomain = lib.mkOption {
        type = types.str;
        default = "";
        example = "example.com";
        description = ''
          Zone this server is reachable under, used to build `domain`'s default. Forwarded from
          `host.network.domain` by `modules/default.nix` so the literal zone never lands in a
          tracked file - only set here to override. Empty by default so that forwarding can be
          unconditional - see the `enable`-gated assertion below.
        '';
      };

      domain = lib.mkOption {
        type = types.nullOr types.str;
        default = if !cfg.caddy || cfg.baseDomain == "" || cfg.subdomains == [ ] then null
          else "https://${builtins.head cfg.subdomains}.${cfg.baseDomain}";
        defaultText = lib.literalExpression ''"https://''${builtins.head subdomains}.''${baseDomain}" when caddy, else null'';
        example = "https://vault.example.com";
        description = ''
          Externally reachable URL clients will use to reach this server. Required for WebAuthn/U2F
          and for icons/links to render correctly. Defaults to `https://<first subdomains
          entry>.<baseDomain>` when `caddy` is set. Set explicitly to override.
        '';
      };

      sopsFile = lib.mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "./secrets.enc.yaml";
        description = ''
          Path to the sops-encrypted file holding the `adminTokenSecretRef` secret, forwarded
          from `host.sopsFile` by `modules/default.nix`. Only required when `enableAdminPanel` is
          set - see that block's assertion below.
        '';
      };

      signupsAllowed = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Whether new user signups are allowed.";
      };

      invitationsAllowed = lib.mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether organization admins can invite new users even with `signupsAllowed` off. Without
          SMTP an invited user registers through the web vault's "Create account" page, so leaving
          this on keeps that link visible. Invites from the `/admin` panel work regardless.
        '';
      };

      enableAdminPanel = lib.mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the `/admin` diagnostics page, protected by the admin token at
          `adminTokenSecretRef` in `sopsFile`.
        '';
      };

      adminTokenSecretRef = lib.mkOption {
        type = types.str;
        default = "vaultwarden/adminToken";
        description = ''
          Key path within `sopsFile` holding the admin token, ideally an Argon2 hash generated with
          `vaultwarden hash`. Only used when `enableAdminPanel` is set.
        '';
      };

      backupDir = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/mnt/Apps/homelab";
        description = ''
          Parent directory to snapshot the data dir into nightly, as `<backupDir>/vaultwarden`,
          overwriting the previous run - see deployment note 6 above. Forwarded from
          `host.backupDir` by `modules/default.nix`. Must be outside `/var/lib/vaultwarden`. `null`
          disables backups.
        '';
      };

      backupTime = lib.mkOption {
        type = types.str;
        default = "23:00";
        example = "Sun 02:30";
        description = ''
          When the nightly `backupDir` snapshot runs, as a systemd `OnCalendar` expression. Only
          used when `backupDir` is set.
        '';
      };

      caddy = lib.mkOption {
        type = types.bool;
        default = true;
        description = ''
          Front Vaultwarden with `services.native.caddy` (enabled by default along with it) at
          `<subdomain>.<domain>` for each `subdomains` entry. When `false`, Vaultwarden listens on
          all interfaces and `port` is opened on the LAN instead.
        '';
      };

      subdomains = lib.mkOption {
        type = listOf types.str;
        default = [ "vault" ];
        example = [ "vault" "vault-vpn" ];
        description = ''
          Subdomains Vaultwarden is served at when `caddy` is enabled - every entry gets its own
          hostname matcher on Caddy's shared wildcard block, all routed to the same backend. The
          first entry is also what `domain` defaults to. List more than one to give this service
          multiple names (e.g. a distinct name for a Pangolin private resource - see deployment
          note 5 above); Caddy treats every entry identically.
        '';
      };

    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # Enable Vaultwarden server
      # - IP_HEADER: the client IP keys the login/admin rate limits. Behind Caddy it arrives in
      #   X-Forwarded-For (Vaultwarden defaults to X-Real-IP, which Caddy doesn't send, so every
      #   client would otherwise share Caddy's 127.0.0.1 bucket). Without Caddy clients connect
      #   directly, so no header is trusted - Vaultwarden's default "local" trust would otherwise
      #   let any LAN client spoof one.
      services.vaultwarden = {
        enable = true;
        backupDir = lib.mkIf (cfg.backupDir != null) "${cfg.backupDir}/vaultwarden";
        config = {
          ROCKET_ADDRESS = if cfg.caddy then "127.0.0.1" else "0.0.0.0";
          ROCKET_PORT = cfg.port;
          SIGNUPS_ALLOWED = cfg.signupsAllowed;
          INVITATIONS_ALLOWED = cfg.invitationsAllowed;
          IP_HEADER = if cfg.caddy then "X-Forwarded-For" else "none";
        } // lib.optionalAttrs (cfg.domain != null) {
          DOMAIN = cfg.domain;
        };
      };

      networking.firewall.allowedTCPPorts = lib.optionals (!cfg.caddy) [ cfg.port ];

      environment.systemPackages = [
        pkgs.vaultwarden      # Vaultwarden server, `vaultwarden hash` generates an Argon2 admin token
      ];
    }

    # Override the upstream backup timer's schedule. Gated on backupDir since upstream only defines
    # the timer then - setting timerConfig unconditionally would create a stray unit
    (lib.mkIf (cfg.backupDir != null) {
      systemd.timers.backup-vaultwarden.timerConfig.OnCalendar = cfg.backupTime;

      # Upstream runs the backup as vaultwarden, which can't write to a CIFS backup share whose files
      # are all forced to the mount's owner and modes - run it as root like the other backup units.
      # Upstream also has wantedBy multi-user, firing a backup on every boot against a share that
      # may not be mounted yet - the timer alone (Persistent, so missed runs still catch up) is enough
      systemd.services.backup-vaultwarden = {
        serviceConfig.User = "root";
        serviceConfig.Group = "root";
        wantedBy = lib.mkForce [ ];
      };

      # Have services.native.alerts watch this backup
      services.native.alerts.enable = lib.mkDefault true;
      services.native.alerts.backup.services = [ "vaultwarden" ];
    })

    # Add a caddy proxy config per subdomain for DNS subdomain resolution
    (lib.mkIf cfg.caddy {
      assertions = [
        { assertion = cfg.subdomains != [ ];
          message = "services.native.vaultwarden with caddy requires at least one 'subdomains' entry"; }
        { assertion = cfg.domain != null;
          message = "services.native.vaultwarden with caddy requires 'baseDomain', normally forwarded from 'host.network.domain', or an explicit 'domain'"; }
      ];

      services.native.caddy.enable = lib.mkDefault true;
      services.native.caddy.proxies = map (s: { subdomain = s; inherit (cfg) port; }) cfg.subdomains;
    })

    # Conditionally enable the admin panel, pulling the token from the sops-nix secret rather than
    # baking it into the nix store
    (lib.mkIf cfg.enableAdminPanel {
      assertions = [
        { assertion = cfg.sopsFile != null;
          message = "services.native.vaultwarden with enableAdminPanel requires 'sopsFile', normally forwarded from 'host.sopsFile'"; }
      ];

      secret.templates."vaultwarden-admin" = {
        filemode = "0400";
        content = ''
          ADMIN_TOKEN=${config.secret.ref.${cfg.adminTokenSecretRef}}
        '';
        secrets.${cfg.adminTokenSecretRef}.sopsFile = cfg.sopsFile;

        # EnvironmentFile is only read at unit start, so a rotated admin token needs a restart
        restartUnits = [ "vaultwarden.service" ];
      };

      services.vaultwarden.environmentFile = config.secret.templates."vaultwarden-admin".path;
    })
  ]);
}
