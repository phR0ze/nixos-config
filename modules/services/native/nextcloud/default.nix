# Nextcloud
#
# ### Description
# File sync and share over the Synology's SMB shares, which Nextcloud connects to directly.
#
# ### Deployment notes
# 1. Wraps upstream `services.nextcloud` (PostgreSQL, Redis, nginx), served through Caddy.
# 2. Users and mounts come from args, keyed by opaque placeholders since sops doesn't encrypt keys:
#    ```yaml
#    nextcloud:
#      smb: { host: 192.168.x.x }
#      users:
#        u1:
#          name: alice
#          passwordSecretRef: nextcloud/u1
#          smb: { user: alice, secretRef: smb/secretA }
#          mounts:
#            m1: { name: Photos, share: home, path: Photos }
#      sharedMounts:
#        s1:
#          name: Family
#          share: photo
#          user: shared
#          secretRef: smb/secretC
#          groups: [ family ]
#          readOnly: true
#    ```
#    - Mount fields fall back to the user's `smb`, then the top-level `smb`.
#    - Keep keys stable: renaming one recreates its mount, changing `name` only updates it.
# 3. `nextcloud-reconcile` only adds or updates. Delete a removed mount with
#    `nextcloud-occ files_external:delete <id>`.
#    - A changed mount password is briefly visible in `/proc`, as `occ` only takes it as an argument.
# 4. Each mount gets an SMB change watcher, which first scans it, unless `notify = false`.
# 5. Pangolin: set `whichDomains = "all"` and add a private `nextcloud-vpn` Newt resource.
#    - Clients and WebDAV can't pass Pangolin's SSO, so a public resource is for browsers only.
# 6. Nightly backup of `/var/lib/nextcloud` and a DB dump to `<backupDir>/nextcloud`.
# 7. Hardened sharing by default, applied by `nextcloud-reconcile` on every run, so changes made in
#    the admin UI are reverted:
#    - Public links are off. With `sharing.links` on they need a password, expire within
#      `sharing.linkExpireDays` (7) days and are download only.
#    - Federated sharing and the lookup server are off. `cloud_federation_api` and
#      `federatedfilesharing` are always-enabled apps, so this is done through config instead.
#    - Resharing and username autocomplete in the share dialog are off.
# 8. Files only by default, every extra below is an option that's off unless enabled:
#    - `apps.<name>`: bundled apps not needed for files. Each is enabled or disabled to match on
#      every reconcile run. Always-enabled apps such as `dav` and `cloud_federation_api` can't be
#      disabled, so their endpoints are blocked in nginx instead (`calDav`, `sharing.federation`).
#    - `userMounts`: users adding their own External Storage, e.g. WebDAV or SFTP into the LAN.
#    - `internetAccess`, `profiles`, `passwordReset`.
#
# ### Backup process
#  sudo systemctl start backup-nextcloud
#
# Restore:
#  sudo systemctl stop nextcloud-cron.timer nextcloud-notify_push 'nextcloud-smb-notify-*' phpfpm-nextcloud
#  sudo rsync -rlt <backupDir>/nextcloud/ /var/lib/nextcloud/
#  sudo chown -R nextcloud:nextcloud /var/lib/nextcloud
#  sudo -u nextcloud pg_restore --clean --if-exists -d nextcloud /var/lib/nextcloud/backups/nextcloud.dump
#  sudo systemctl start phpfpm-nextcloud nextcloud-cron.timer nextcloud-notify_push
#  sudo nextcloud-occ maintenance:mode --off
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.services.native.nextcloud;
  home = config.services.nextcloud.home;
  stateDir = "${home}/reconcile";

  # Zones Caddy serves this app on, matching `f.caddyProxies`
  zones = if cfg.whichDomains == "all" then cfg.domains else lib.take 1 cfg.domains;

  # Unit- and file-name safe string, e.g. "Family Photos" -> "Family-Photos"
  safe = s: lib.concatMapStrings (c: if builtins.match "[A-Za-z0-9_.-]" c != null then c else "-")
    (lib.stringToCharacters s);

  # First non-null `field` along a fallback chain of smb settings
  pick = chain: field: lib.findFirst (x: x != null) null (map (s: s.${field}) chain);

  # SMB connection settings, at the top level, per user and per mount
  smbOptions = {
    host = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "SMB server address.";
    };
    user = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "SMB (Synology) account to connect as.";
    };
    domain = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "SMB domain or workgroup of `user`.";
    };
    secretRef = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "smb/secretA";
      description = "Key in `sopsFile` holding `user`'s SMB password.";
    };
  };

  mountOptions = smbOptions // {
    name = lib.mkOption {
      type = types.str;
      example = "Photos";
      description = "Folder name shown in Nextcloud.";
    };
    share = lib.mkOption {
      type = types.str;
      description = "Name of the SMB share.";
    };
    path = lib.mkOption {
      type = types.str;
      default = "";
      example = "alice/Photos";
      description = "Subfolder within `share`, e.g. `Photos` for `//<host>/<share>/Photos`.";
    };
    previews = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Generate previews for this mount.";
    };
    notify = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Watch for changes made on the NAS, see deployment note 4.";
    };
  };

  # One resolved mount, the shape reconcile.sh consumes
  mkMount = { id, key, chain, m, users, groups, readOnly }: {
    id = safe id;
    inherit key users groups;
    inherit (m) notify;
    mountPoint = "/${m.name}";
    secretRef = pick chain "secretRef";
    passwordFile = let ref = pick chain "secretRef"; in
      if ref == null then null else config.secret.templates."nextcloud-smb-${safe ref}".path;
    configuration = {
      host = pick chain "host";
      user = pick chain "user";
      domain = let d = pick chain "domain"; in if d == null then "" else d;
      inherit (m) share;
      root = m.path;  # Nextcloud's name for the subfolder
    };
    options = {
      readonly = readOnly;
      inherit (m) previews;
      filesystem_check_changes = if m.notify then 0 else 1;
    };
  };

  # Ids come from the args keys, so they survive a change of `name`
  userMounts = lib.concatLists (lib.mapAttrsToList (ukey: u: lib.mapAttrsToList (mkey: m: mkMount {
    id = "${ukey}-${mkey}"; key = "${u.name}/${m.name}"; inherit m;
    chain = [ m u.smb cfg.smb ];
    users = [ u.name ]; groups = [ ]; readOnly = false;
  }) u.mounts) cfg.users);

  sharedMounts = lib.mapAttrsToList (skey: m: mkMount {
    id = skey; key = "shared/${m.name}"; inherit m;
    chain = [ m cfg.smb ];
    users = map (k: cfg.users.${k}.name or k) m.users;
    inherit (m) groups readOnly;
  }) cfg.sharedMounts;

  mounts = userMounts ++ sharedMounts;
  notifyMounts = lib.filter (m: m.notify) mounts;

  declaredGroups = lib.unique (lib.concatMap (u: u.groups) (lib.attrValues cfg.users));

  # Default-enabled bundled apps, from core/shipped.json, that a files-only server doesn't need.
  # Each becomes an `apps.<name>` option, see deployment note 8
  optionalApps = {
    app_api = "ExApps, external apps run through Docker deploy daemons";
    circles = "Teams, a second sharing system";
    comments = "comments on files";
    contactsinteraction = "contacts collected from interactions";
    dashboard = "the dashboard start page";
    federation = "trusted servers, syncing users with other Nextcloud servers";
    files_downloadlimit = "download limits on public link shares";
    files_reminders = "file reminders";
    firstrunwizard = "the first-login wizard";
    nextcloud_announcements = "announcements fetched from nextcloud.com";
    photos = "the Photos app";
    privacy = "the privacy settings page";
    recommendations = "file recommendations";
    related_resources = "related resources in the sidebar";
    serverinfo = "the server info page and its monitoring API";
    sharebymail = "sharing by email";
    support = "the support settings page";
    survey_client = "usage statistics sent to nextcloud.com";
    updatenotification = "update checks against nextcloud.com, Nix manages updates";
    user_status = "user statuses";
    weather_status = "the weather widget, which calls an external weather API";
    webhook_listeners = "webhooks, HTTP requests to admin-chosen URLs";
  };

  yesNo = b: if b then "yes" else "no";
  sh = cfg.sharing;
  expires = sh.linkExpireDays != null;

  # App config values as `app.key = value`, applied by reconcile.sh on every run
  appConfig = {
    files.default_quota = cfg.defaultQuota;
    files_external.allow_user_mounting = yesNo cfg.userMounts;
    core = {
      shareapi_allow_resharing = yesNo sh.resharing;
      shareapi_allow_share_dialog_user_enumeration = yesNo sh.userEnumeration;
      shareapi_allow_links = yesNo sh.links;
      shareapi_enforce_links_password = yesNo sh.linkPassword;
      shareapi_allow_public_upload = yesNo sh.linkUpload;
      shareapi_default_expire_date = yesNo expires;
      shareapi_enforce_expire_date = yesNo expires;
      shareapi_allow_federation_on_public_shares = yesNo sh.federation;
    } // lib.optionalAttrs expires {
      shareapi_expire_after_n_days = toString sh.linkExpireDays;
    };
    files_sharing = lib.genAttrs [
      "outgoing_server2server_share_enabled"
      "incoming_server2server_share_enabled"
      "outgoing_server2server_group_share_enabled"
      "incoming_server2server_group_share_enabled"
      "lookupServerEnabled"
      "lookupServerUploadEnabled"
    ] (_: yesNo sh.federation);
  };

  # Desired state for reconcile.sh, passwords referenced by file
  desired = pkgs.writeText "nextcloud-desired.json" (builtins.toJSON {
    inherit (cfg) adminUser apps;
    inherit appConfig;
    groups = declaredGroups;
    users = lib.mapAttrsToList (ukey: u: {
      uid = u.name;
      inherit (u) displayName groups quota;
      passwordFile = config.secret.templates."nextcloud-user-${safe ukey}".path;
    }) cfg.users;
    mounts = map (m: builtins.removeAttrs m [ "secretRef" ]) mounts;
  });

  reconcile = pkgs.writeShellApplication {
    name = "nextcloud-reconcile";
    runtimeInputs = [ config.services.nextcloud.occ pkgs.jq pkgs.coreutils ];
    text = builtins.readFile ./reconcile.sh;
  };

  # A single secret value, readable by nextcloud
  secretTemplate = ref: {
    user = "nextcloud";
    group = "nextcloud";
    filemode = "0400";
    content = config.secret.ref.${ref};
    secrets.${ref}.sopsFile = cfg.sopsFile;
    restartUnits = [ "nextcloud-reconcile.service" ];
  };
in
{
  options = {
    # `domains`/`whichDomains`: which Caddy zones it's served on, see modules/types/caddy_domains.nix
    services.native.nextcloud = (import ../../../types/caddy_domains.nix { inherit lib; }) // {
      enable = lib.mkEnableOption "Install and configure Nextcloud server";

      port = lib.mkOption {
        type = types.port;
        default = 8090;
        description = "Port nginx serves Nextcloud on.";
      };

      caddy = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Serve through `services.native.caddy`, else plain HTTP on the LAN at `port`.";
      };

      subdomains = lib.mkOption {
        type = listOf types.str;
        default = [ "nextcloud" ];
        example = [ "nextcloud" "nextcloud-vpn" ];
        description = "Subdomains served when `caddy` is set. The first, on the primary zone, is `hostName`.";
      };

      hostName = lib.mkOption {
        type = types.nullOr types.str;
        default = if !cfg.caddy || cfg.domains == [ ] || cfg.subdomains == [ ] then null
          else "${lib.head cfg.subdomains}.${lib.head cfg.domains}";
        defaultText = lib.literalExpression ''"''${lib.head subdomains}.''${lib.head domains}" when caddy, else null'';
        example = "nextcloud.example.com";
        description = "Canonical name for generated links and the nginx virtual host.";
      };

      sopsFile = lib.mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "./secrets.enc.yaml";
        description = "sops file holding the passwords, forwarded from `host.sopsFile`.";
      };

      adminUser = lib.mkOption {
        type = types.str;
        default = "admin";
        description = "Name of the admin account created on first setup.";
      };

      adminPasswordSecretRef = lib.mkOption {
        type = types.str;
        default = "nextcloud/adminPassword";
        description = "Key in `sopsFile` holding the admin's initial password.";
      };

      maxUploadSize = lib.mkOption {
        type = types.str;
        default = "16G";
        description = "Largest upload accepted, also PHP's memory limit.";
      };

      phpMaxChildren = lib.mkOption {
        type = types.ints.between 12 1000;
        default = 32;
        description = "PHP-FPM `pm.max_children`. Workers use up to ~100 MB each.";
      };

      defaultQuota = lib.mkOption {
        type = types.str;
        default = "1 GB";
        description = "Default quota for local storage, SMB mounts excluded.";
      };

      sharing = {
        links = lib.mkOption {
          type = types.bool;
          default = false;
          description = "Allow public link shares, which publish files to anyone holding the link.";
        };
        linkPassword = lib.mkOption {
          type = types.bool;
          default = true;
          description = "Require a password on public link shares.";
        };
        linkUpload = lib.mkOption {
          type = types.bool;
          default = false;
          description = "Allow uploads through public link shares of folders.";
        };
        linkExpireDays = lib.mkOption {
          type = types.nullOr types.ints.positive;
          default = 7;
          description = "Enforced maximum, and default, lifetime of public link shares. `null` for no expiry.";
        };
        federation = lib.mkOption {
          type = types.bool;
          default = false;
          description = "Allow federated (cross-server) sharing and the lookup server, else their endpoints are blocked.";
        };
        resharing = lib.mkOption {
          type = types.bool;
          default = false;
          description = "Allow recipients to reshare files shared with them.";
        };
        userEnumeration = lib.mkOption {
          type = types.bool;
          default = false;
          description = "Autocomplete other users' names in the share dialog, which reveals who has an account.";
        };
      };

      # See deployment note 8
      apps = lib.mapAttrs (_: desc: lib.mkEnableOption desc) optionalApps;

      userMounts = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Let users add their own External Storage, which could reach into the LAN.";
      };

      calDav = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Serve the always-enabled CalDAV and CardDAV endpoints, else nginx blocks them.";
      };

      internetAccess = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Let Nextcloud make its own outbound checks, e.g. for updates.";
      };

      profiles = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Enable user profile pages, which can be made public.";
      };

      passwordReset = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Show the email password reset link on the login page.";
      };

      smb = smbOptions;

      users = lib.mkOption {
        default = { };
        description = "Users keyed by an opaque placeholder, see deployment note 2.";
        type = attrsOf (submodule {
          options = {
            name = lib.mkOption {
              type = types.str;
              example = "alice";
              description = "Nextcloud login name.";
            };
            displayName = lib.mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Display name, the login name when null.";
            };
            passwordSecretRef = lib.mkOption {
              type = types.str;
              example = "nextcloud/u1";
              description = "Key in `sopsFile` holding the initial password, only used on create.";
            };
            groups = lib.mkOption {
              type = listOf types.str;
              default = [ ];
              description = "Groups the user is added to, created if missing.";
            };
            quota = lib.mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "5 GB";
              description = "Local home storage quota, `defaultQuota` when null.";
            };
            smb = smbOptions;
            mounts = lib.mkOption {
              default = { };
              description = "Writable mounts only this user sees, keyed by an opaque placeholder.";
              type = attrsOf (submodule { options = mountOptions; });
            };
          };
        });
      };

      sharedMounts = lib.mkOption {
        default = { };
        description = "Mounts shown to several users and/or groups, keyed by an opaque placeholder.";
        type = attrsOf (submodule {
          options = mountOptions // {
            users = lib.mkOption {
              type = listOf types.str;
              default = [ ];
              example = [ "u1" ];
              description = "Keys of the declared users who see this mount.";
            };
            groups = lib.mkOption {
              type = listOf types.str;
              default = [ ];
              description = "Declared groups whose members see this mount.";
            };
            readOnly = lib.mkOption {
              type = types.bool;
              default = false;
              description = "Mount it read-only in Nextcloud.";
            };
          };
        });
      };

      backupDir = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/mnt/Apps/homelab";
        description = "Nightly backup parent dir, see deployment note 6. `null` disables backups.";
      };

      backupTime = lib.mkOption {
        type = types.str;
        default = "03:30";
        example = "Sun 02:30";
        description = "When the backup runs, as a systemd `OnCalendar` expression.";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        { assertion = cfg.sopsFile != null;
          message = "services.native.nextcloud requires 'sopsFile', normally forwarded from 'host.sopsFile'"; }
        { assertion = cfg.hostName != null;
          message = "services.native.nextcloud requires 'hostName', the default needs caddy with 'domains' and 'subdomains'"; }
        { assertion = lib.allUnique (map (m: m.id) mounts);
          message = "services.native.nextcloud users, mounts and sharedMounts keys must stay unique once joined and symbols become '-'"; }
        { assertion = lib.allUnique (map (u: u.name) (lib.attrValues cfg.users));
          message = "services.native.nextcloud has two users with the same 'name'"; }
      ] ++ map (m: {
        assertion = m.configuration.host != null && m.configuration.user != null && m.secretRef != null;
        message = "services.native.nextcloud mount '${m.key}' needs a host, user and secretRef, set on the mount, its user's smb or the top-level smb";
      }) mounts
      ++ lib.mapAttrsToList (key: m: {
        assertion = m.users != [ ] || m.groups != [ ];
        message = "services.native.nextcloud shared mount '${key}' needs at least one user or group, an empty list would show it to everyone";
      }) cfg.sharedMounts
      ++ lib.mapAttrsToList (key: m: {
        assertion = lib.all (u: cfg.users ? ${u}) m.users && lib.all (g: lib.elem g declaredGroups) m.groups;
        message = "services.native.nextcloud shared mount '${key}' lists a user key or group that isn't declared in 'users'";
      }) cfg.sharedMounts
      # Nextcloud can't show two mounts at the same path to the same user
      ++ lib.mapAttrsToList (ukey: u: let
        own = map (m: m.name) (lib.attrValues u.mounts);
        visible = lib.filter (s: lib.elem ukey s.users || lib.any (g: lib.elem g s.groups) u.groups)
          (lib.attrValues cfg.sharedMounts);
        names = own ++ map (s: s.name) visible;
      in {
        assertion = lib.allUnique names;
        message = "services.native.nextcloud user '${ukey}' can see two mounts with the same 'name'";
      }) cfg.users;

      # - trusted_proxies: only Caddy may set X-Forwarded-For, which brute-force protection uses
      # - skeletondirectory: no sample files for new users
      services.nextcloud = {
        enable = true;
        package = pkgs.nextcloud33;
        hostName = cfg.hostName;
        https = cfg.caddy;
        database.createLocally = true;
        config = {
          dbtype = "pgsql";
          adminuser = cfg.adminUser;
          adminpassFile = config.secret.templates."nextcloud-admin".path;
        };
        configureRedis = true;
        caching.apcu = true;
        appstoreEnable = false;
        extraAppsEnable = true;
        extraApps = { inherit (config.services.nextcloud.package.packages.apps) previewgenerator; };
        phpExtraExtensions = all: [ all.smbclient ];
        maxUploadSize = cfg.maxUploadSize;
        phpOptions = {
          "opcache.interned_strings_buffer" = "32";
          "opcache.memory_consumption" = "256";
          "opcache.max_accelerated_files" = "20000";
          "opcache.revalidate_freq" = "60";
        };
        poolSettings = {
          "pm" = "dynamic";
          "pm.max_children" = toString cfg.phpMaxChildren;
          "pm.start_servers" = "6";
          "pm.min_spare_servers" = "4";
          "pm.max_spare_servers" = "12";
          "pm.max_requests" = "500";
          "pm.status_path" = "/status";
        };
        settings = {
          trusted_domains = if cfg.caddy
            then lib.concatMap (zone: map (sub: "${sub}.${zone}") cfg.subdomains) zones
            else [ ];
          trusted_proxies = lib.optionals cfg.caddy [ "127.0.0.1" ];
          overwriteprotocol = lib.mkIf cfg.caddy "https";
          maintenance_window_start = 1;
          skeletondirectory = "";
          defaultapp = if cfg.apps.dashboard then "dashboard,files" else "files";
          has_internet_connection = cfg.internetAccess;
          updatechecker = cfg.internetAccess;
          "profile.enabled" = cfg.profiles;
          lost_password_link = lib.mkIf (!cfg.passwordReset) "disabled";
          knowledgebaseenabled = false;
          "simpleSignUpLink.shown" = false;
          log_type = "file";
          loglevel = 2;
          preview_max_x = 2048;
          preview_max_y = 2048;
          preview_max_scale_factor = 1;
          preview_max_filesize_image = 50;
          jpeg_quality = 60;
          enabledPreviewProviders = [
            "OC\\Preview\\PNG"
            "OC\\Preview\\JPEG"
            "OC\\Preview\\GIF"
            "OC\\Preview\\BMP"
            "OC\\Preview\\XBitmap"
            "OC\\Preview\\HEIC"
            "OC\\Preview\\WebP"
            "OC\\Preview\\MP3"
            "OC\\Preview\\TXT"
            "OC\\Preview\\MarkDown"
            "OC\\Preview\\OpenDocument"
            "OC\\Preview\\Krita"
          ];
        };

        # Pushes changes to clients instead of polling, via local Caddy for the real certificate
        notify_push = {
          enable = true;
          nextcloudUrl = if cfg.caddy then "https://${cfg.hostName}" else "http://127.0.0.1:${toString cfg.port}";
        };
      };

      # Our own name resolves to local Caddy, for notify_push
      networking.hosts."127.0.0.1" = lib.mkIf cfg.caddy [ cfg.hostName ];

      # Endpoints of always-enabled apps that can't be disabled, see deployment note 8. Regexes run
      # before upstream's `\.php` handler, exact matches before its `/.well-known` prefix
      services.nginx.virtualHosts.${cfg.hostName} = {
        listen = [ { addr = if cfg.caddy then "127.0.0.1" else "0.0.0.0"; port = cfg.port; } ];
        locations = lib.optionalAttrs (!cfg.calDav) {
          "~ ^/remote\\.php/(?:caldav|carddav|dav/(?:calendars|addressbooks|public-calendars))(?:$|/)" = {
            priority = 450;
            return = "404";
          };
          "= /.well-known/caldav".return = "404";
          "= /.well-known/carddav".return = "404";
        } // lib.optionalAttrs (!sh.federation) {
          "~ ^/(?:index\\.php/)?(?:ocm-provider|ocs-provider|ocm)(?:$|/)" = {
            priority = 450;
            return = "404";
          };
          "= /.well-known/ocm".return = "404";
        };
      };
      networking.firewall.allowedTCPPorts = lib.optionals (!cfg.caddy) [ cfg.port ];

      secret.templates = {
        # Read by upstream as root, on first setup only
        "nextcloud-admin" = {
          filemode = "0400";
          content = config.secret.ref.${cfg.adminPasswordSecretRef};
          secrets.${cfg.adminPasswordSecretRef}.sopsFile = cfg.sopsFile;
        };
      }
      // lib.mapAttrs' (ukey: u: lib.nameValuePair "nextcloud-user-${safe ukey}" (secretTemplate u.passwordSecretRef)) cfg.users
      // lib.listToAttrs (map (ref: lib.nameValuePair "nextcloud-smb-${safe ref}" (secretTemplate ref))
        (lib.unique (lib.filter (r: r != null) (map (m: m.secretRef) mounts))));

      # SMB watchers, see deployment note 4. Started after boot once the network is up, retried
      # while the NAS is down. Watching needs the smbclient binary
      # - Mounts never check for changes themselves, so each start first scans the mount, through
      #   a user who sees it, to pick up existing files and anything missed while it was down
      systemd.services = lib.listToAttrs (map (m: lib.nameValuePair "nextcloud-smb-notify-${m.id}" {
        description = "Watch Nextcloud mount ${m.key} for SMB changes";
        after = [ "nextcloud-reconcile.service" ];
        wants = [ "nextcloud-reconcile.service" ];
        # Restart, and so rescan, when the mount's settings change, e.g. a new `path`
        restartTriggers = [ (builtins.toJSON m) ];
        path = [ config.services.nextcloud.occ pkgs.samba pkgs.coreutils pkgs.jq ];
        script = ''
          user=${if m.users != [ ] then lib.escapeShellArg (lib.head m.users) else ''
            $(nextcloud-occ group:list --output=json \
              | jq -r --argjson g ${lib.escapeShellArg (builtins.toJSON m.groups)} \
                'first(. as $l | $g[] | $l[.][]?) // empty')''}
          if [ -n "$user" ]; then
            nextcloud-occ files:scan --path="/$user/files"${lib.escapeShellArg m.mountPoint}
          fi
          exec nextcloud-occ files_external:notify "$(cat ${stateDir}/${m.id}.id)"
        '';
        serviceConfig = {
          User = "nextcloud";
          Group = "nextcloud";
          Restart = "always";
          RestartSec = 30;
        };
      }) notifyMounts) // {
        # See deployment note 3. RemainAfterExit so a changed desired state reruns it on switch
        nextcloud-reconcile = {
          description = "Apply declared Nextcloud users, groups and SMB mounts";
          after = [ "nextcloud-setup.service" ];
          requires = [ "nextcloud-setup.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "nextcloud";
            Group = "nextcloud";
            UMask = "0077";
            RuntimeDirectory = "nextcloud-reconcile";
            RuntimeDirectoryMode = "0700";
            ExecStart = "${lib.getExe reconcile} ${desired} ${stateDir}";
          };
        };

        nextcloud-previews = {
          description = "Pre-generate Nextcloud previews";
          after = [ "nextcloud-setup.service" ];
          serviceConfig = {
            Type = "oneshot";
            User = "nextcloud";
            Group = "nextcloud";
            ExecStart = "${lib.getExe config.services.nextcloud.occ} preview:pre-generate";
          };
        };
      };

      systemd.timers.nextcloud-previews = {
        description = "Pre-generate Nextcloud previews every 15 minutes";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*:0/15";
          Persistent = true;
        };
      };

      devices.network.onlineServices = map (m: "nextcloud-smb-notify-${m.id}") notifyMounts;
    }

    # Nightly backup, see deployment note 6
    # - Root and -rlt: the CIFS backup share forces its own owner and modes
    # - No wantedBy, so it never runs at boot against an unmounted share
    (lib.mkIf (cfg.backupDir != null) (let
      backupDir = "${cfg.backupDir}/nextcloud";
    in {
      assertions = [
        { assertion = !(lib.hasPrefix "${home}/" "${backupDir}/");
          message = "services.native.nextcloud.backupDir must be outside ${home}"; }
      ];

      systemd.tmpfiles.rules = [ "d ${home}/backups 0750 nextcloud nextcloud -" ];

      # Have services.native.alerts watch this backup
      services.native.alerts.enable = lib.mkDefault true;
      services.native.alerts.backup.services = [ "nextcloud" ];

      systemd.services.backup-nextcloud = {
        description = "Backup Nextcloud data, config and database";
        path = [ pkgs.rsync pkgs.util-linux config.services.nextcloud.occ config.services.postgresql.package ];
        serviceConfig.Type = "oneshot";
        script = ''
          set -euo pipefail
          nextcloud-occ maintenance:mode --on
          trap 'nextcloud-occ maintenance:mode --off' EXIT

          runuser -u nextcloud -- pg_dump -Fc -f ${home}/backups/nextcloud.dump nextcloud

          mkdir -p ${backupDir}
          rsync -rlt --delete \
            --exclude='/data/appdata_*/preview/' --exclude='/data/updater-*' \
            --exclude=/nix-apps --exclude=/store-apps \
            ${home}/ ${backupDir}/
        '';
      };

      systemd.timers.backup-nextcloud = {
        description = "Backup Nextcloud nightly";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.backupTime;
          Persistent = true;
        };
      };
    }))

    # One Caddy proxy per subdomain
    (lib.mkIf cfg.caddy {
      assertions = [
        { assertion = cfg.subdomains != [ ];
          message = "services.native.nextcloud with caddy requires at least one 'subdomains' entry"; }
        (f.caddyDomainsAssert "native.nextcloud" cfg)
      ];

      services.native.caddy.enable = lib.mkDefault true;
      services.native.caddy.domains = f.caddyProxies cfg (map (sub: { subdomain = sub; inherit (cfg) port; }) cfg.subdomains);

      # notify_push reaches Nextcloud through Caddy over loopback and checks its X-Forwarded-For
      # survives, which Caddy only keeps from a trusted proxy
      services.native.caddy.trustedProxies = [ "127.0.0.1/32" ];
    })
  ]);
}
