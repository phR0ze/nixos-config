# Adguard Home configuration
# - https://github.com/AdguardTeam/AdGuardHome
# - https://adguard.com/en/adguard-home/overview.html
#
# ### Description
# Privacy protection center for you and your devices. Free and open source, powerful network-wide ads
# and trackers blocking DNS server. Adguard Home operates as a DNS server that re-routes tarcking
# domains to a "black-hole", thus preventing your devices from connecting to those servers
#
# - Blocking ads and trackers
# - Customizing blocklists
# - Built-in DHCP server
# - HTTPS for the Admin interface
# - Encrypted DNS upstream servers
# - Blocking phishing and malware domains
# - Parental control (blocking adult domains)
# - Force Safe search on search engines
#
# ### Deployment Features
# - App is exposed to the LAN as a first class citizen to allow it to log correct IP addresses
# - App data is persisted at /var/lib/$APP
#
# ### Generate password
# 1. nix shell nixpkgs#apacheHttpd -c htpasswd -nbB <USER> <PASSWORD>"
# 2. Trim off the prefix <USER>: and store the remaining portion
#    e.g. $2y$05$x3123cn5Kcr/6JRpXfxXYulhrxSIVtTQvwYDzMgzba.bZ6cT78cwa
#
# ### Backup process
# - `<backupDir>/adguardhome` gets a nightly snapshot at `backupTime` of `/var/lib/AdGuardHome` minus its
#   downloaded blocklists: the service is stopped, the data dir rsynced over, then the service
#   restarted. Each run overwrites the last
# - `data/stats.db` and `data/sessions.db` are bbolt files written live, so stopping is the simplest
#   way to get a consistent copy. LAN DNS is down for the few seconds the copy takes
# - `data/filters/` is re-downloaded from the filter URLs on start and is skipped
#
# **Trigger backup**
# sudo systemctl start backup-adguardhome
#
# #### Restore
# The backup share doesn't preserve ownership or modes (everything comes back with the mount's
# forced owner and modes), so the restore copies content only (`-rlt`, leaving the live dirs'
# modes alone) and then resets ownership recursively.
#
# 1. Stop the service
#    sudo systemctl stop adguardhome
#
# 2. Restore the data
#    sudo rsync -rlt --delete --exclude=/data/filters/ <backupDir>/adguardhome/ /var/lib/AdGuardHome/
#
# 3. Reset ownership. The DynamicUser has no fixed name, so take its uid/gid from the data dir
#    itself, which `-rlt` left alone. systemd only checks the top-level dir's owner on start, so
#    it won't fix the root-owned files rsync just wrote on its own.
#    sudo chown -R "$(sudo stat -c %u:%g /var/lib/private/AdGuardHome)" /var/lib/private/AdGuardHome
#
# 4. Start the service
#    sudo systemctl start adguardhome
#
# ### Services
# - podman-adguard
# - podman-network-adguard
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }:
let
  cfg = config.services.native.adguardhome;

  # The LAN zone the split-horizon rewrite covers - only the primary, so other zones (e.g. a
  # Pangolin server's, whose dashboard must stay reachable) still resolve publicly
  primaryDomain = if cfg.domains == [ ] then "" else lib.head cfg.domains;

  # `services.adguardhome.settings` is compiled straight into a Nix-store YAML derivation at eval
  # time -- there's no environmentFile-style escape hatch for it -- so a real secret can't be
  # substituted into it at all (a sops placeholder would only render literally, not decrypt, since
  # that only happens through sops-nix's own template-rendering activation step). So `settings.users`
  # is left unset entirely and the admin user is (re)written into AdGuardHome's own persisted config
  # at activation via `preStart`, reading the admin's name and precomputed htpasswd hash from the
  # runtime secrets (decrypted to config.secret.files."${cfg.userSecretRef}"/"${cfg.htpasswdSecretRef}".path)
  # instead of hashing at eval time -- the same "patch the app's own config file at activation"
  # approach modules/services/native/jellyfin.nix already uses for network.xml.
  patchAdminUser = pkgs.writeShellScript "adguardhome-patch-admin-user" ''
    set -euo pipefail
    export NAME="$(cat ${config.secret.files.${cfg.userSecretRef}.path})"
    export HASH="$(cat ${config.secret.files.${cfg.htpasswdSecretRef}.path})"
    ${pkgs.yq-go}/bin/yq -i '.users = [{"name": strenv(NAME), "password": strenv(HASH)}]' \
      /var/lib/AdGuardHome/AdGuardHome.yaml
  '';

  # Global safe search engines, also reused by clients that enable their own safe search
  safeSearch = {
    enabled = true;
    bing = true;
    duckduckgo = true;
    ecosia = true;
    google = true;
    pixabay = true;
    yandex = true;
    youtube = true;
  };

  # AdGuard's YAML form of a persistent client. Every field is written out because any boolean
  # AdGuard doesn't find defaults to false, e.g. a missing `use_global_settings` would silently
  # switch the client to its own settings with filtering off. `uid` is left out and AdGuard
  # generates one on load.
  toClient = c: {
    inherit (c) name ids tags upstreams;
    use_global_settings = c.useGlobalSettings;
    filtering_enabled = c.filtering;
    parental_enabled = c.parental;
    safebrowsing_enabled = c.safeBrowsing;
    safe_search = if c.safeSearch then safeSearch else lib.mapAttrs (_: _: false) safeSearch;
    use_global_blocked_services = c.blockedServices == null;
    blocked_services = {
      schedule.time_zone = "Local";
      ids = if c.blockedServices == null then [ ] else c.blockedServices;
    };
    upstreams_cache_enabled = false;
    upstreams_cache_size = 0;
    ignore_querylog = c.ignoreQueryLog;
    ignore_statistics = c.ignoreStatistics;
  };
in
{
  options = {
    # `domains`/`whichDomains`: which Caddy zones it's served on, see modules/types/caddy_domains.nix
    services.native.adguardhome = (import ../../../types/caddy_domains.nix { inherit lib; }) // {
      enable = lib.mkEnableOption "Install and configure Adguard Home server";

      bindAddress = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "192.168.x.x";
        description = ''
          LAN IP address AdGuard Home binds its admin HTTP interface and DNS listener to. Bound
          explicitly to this machine's LAN-facing IP rather than `0.0.0.0` so client requests are
          correctly attributed to the LAN interface (see the module header's "exposed to the LAN
          as a first class citizen" note) and the listener stays unreachable from any other
          interface on the host. Nullable so that forwarding can be unconditional - see the
          `enable`-gated assertion below for the actual requirement.
        '';
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 3000;
        description = "Port the AdGuard Home admin web interface listens on.";
      };

      caddy = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Front the admin interface with `services.native.caddy` (enabled by default along with it)
          at `<subdomain>.<zone>` (see `whichDomains`). When `false`, the admin port is opened on the
          LAN instead.
        '';
      };

      subdomain = lib.mkOption {
        type = lib.types.str;
        default = "adguard";
        description = "Subdomain the admin interface is served at when `caddy` is enabled.";
      };

      unblockedDomains = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "api.mixpanel.com"
          "oli.vi"
          "track.byustore.com"
          "email2.harri.com"
          "cdn.harri.com"
          "harri.com"
          "wallet-api.urbanairship.com"
          "forms.gle"
          "www.bark.us"
          "bcove.video"
          "nexus-websocket-a.intercom.io"
          "bit.ly"
        ];
        example = [ "bit.ly" "*.example.com" ];
        description = ''
          Domains always allowed through, overriding every blocklist. Each one becomes an
          `@@||<domain>^$important` rule, which also covers its subdomains. Wildcards are
          supported. Setting this replaces the defaults; set it with `lib.mkOptionDefault` to add to
          them instead. `*.<primary domain>` (the first of `domains`) is always appended.
        '';
      };

      dnsRewrites = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            domain = lib.mkOption {
              type = lib.types.str;
              example = "vault.example.com";
              description = "Domain to rewrite. Wildcards are supported, e.g. `*.example.com`.";
            };
            answer = lib.mkOption {
              type = lib.types.str;
              example = "192.168.x.x";
              description = "IP address (or CNAME target) returned for `domain`.";
            };
          };
        });
        default = [ ];
        example = [ { domain = "vault.example.com"; answer = "192.168.x.x"; } ];
        description = ''
          DNS rewrites served to LAN clients. Merged with the module's own built-in rewrites
          (`adguard.local` and the split-horizon `*.<primary domain>`), so setting this adds to them
          rather than replacing them.
        '';
      };

      clients = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              example = "Workstation";
              description = "Display name of the client, must be unique.";
            };
            ids = lib.mkOption {
              type = lib.types.nonEmptyListOf lib.types.str;
              example = [ "192.168.x.x" ];
              description = "IPs, CIDRs, MACs or ClientIDs identifying the client.";
            };
            tags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              example = [ "device_pc" ];
              description = "AdGuard client tags, usable in `$ctag` filtering rules.";
            };
            upstreams = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Per-client upstream DNS servers. Empty uses the global upstreams.";
            };
            useGlobalSettings = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Use the global filtering settings. When `false`, the `filtering`, `parental`,
                `safeBrowsing` and `safeSearch` options below apply to this client instead.
              '';
            };
            filtering = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Apply blocklists. Only used when `useGlobalSettings` is `false`.";
            };
            parental = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Apply parental control. Only used when `useGlobalSettings` is `false`.";
            };
            safeBrowsing = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Apply safe browsing. Only used when `useGlobalSettings` is `false`.";
            };
            safeSearch = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Enforce safe search, with the same per-engine choices as the global setting. Only
                used when `useGlobalSettings` is `false`.
              '';
            };
            blockedServices = lib.mkOption {
              type = lib.types.nullOr (lib.types.listOf lib.types.str);
              default = null;
              example = [ "tiktok" "discord" ];
              description = ''
                Service ids to block for this client instead of the global blocked services. `null`
                uses the global list.
              '';
            };
            ignoreQueryLog = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Leave this client's queries out of the query log.";
            };
            ignoreStatistics = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Leave this client's queries out of the statistics.";
            };
          };
        });
        default = [ ];
        example = [ { name = "Workstation"; ids = [ "192.168.x.x" ]; ignoreQueryLog = true; } ];
        description = ''
          Persistent clients. Forwarded from `host.services.native.adguardhome.clients` in
          `args.enc.yaml` by `modules/default.nix` to keep device names and LAN IPs untracked.
          When non-empty this is the complete list: upstream merges `settings` into the live config
          on every start and replaces lists outright, so clients added in the web UI are dropped on
          the next restart. Leave empty to manage clients in the web UI instead.
        '';
      };

      sopsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = "./secrets.enc.yaml";
        description = ''
          Path to this host's sops-encrypted secrets, holding the entries (keyed by
          `userSecretRef`/`htpasswdSecretRef` below) the admin account is (re)written from at
          activation. Forwarded from `host.sopsFile` by `modules/default.nix`. Nullable so that
          forwarding can be unconditional - see the `enable`-gated assertion below for the actual
          requirement.
        '';
      };

      userSecretRef = lib.mkOption {
        type = lib.types.str;
        default = "adguard/user";
        description = ''
          Key path within `sopsFile` holding the admin account's plaintext username.
        '';
      };

      htpasswdSecretRef = lib.mkOption {
        type = lib.types.str;
        default = "adguard/htpasswd";
        description = ''
          Key path within `sopsFile` holding the admin account's precomputed htpasswd hash (see
          the password-reset instructions at the top of this file for how to generate it).
        '';
      };

      backupDir = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/mnt/Apps/homelab";
        description = ''
          Parent directory to snapshot the data dir into nightly, as `<backupDir>/adguardhome`, overwriting
          the previous run - see the backup process notes above. Forwarded from `host.backupDir` by
          `modules/default.nix`. Must be outside `/var/lib/AdGuardHome`. `null` disables backups.
        '';
      };

      backupTime = lib.mkOption {
        type = lib.types.str;
        default = "00:30";
        example = "Sun 02:30";
        description = ''
          When the nightly `backupDir` snapshot runs, as a systemd `OnCalendar` expression. DNS is
          down for the duration of the run, so pick a time the LAN is quiet.
        '';
      };
    };
  };
 
  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        { assertion = cfg.sopsFile != null;
            message = "services.native.adguard requires 'sopsFile', normally forwarded from 'host.sopsFile'";
        }
        { assertion = cfg.bindAddress != null && cfg.bindAddress != "";
            message = "services.native.adguard requires 'bindAddress', is 'devices.network.primary.ip' set for this host?";
        }
        # AdGuard refuses to start, taking LAN DNS down with it, on a duplicate client name or id
        (let names = map (c: c.name) cfg.clients; in {
          assertion = lib.length names == lib.length (lib.unique names);
          message = "services.native.adguardhome.clients has duplicate names: ${toString names}";
        })
        (let ids = lib.concatMap (c: c.ids) cfg.clients; in {
          assertion = lib.length ids == lib.length (lib.unique ids);
          message = "services.native.adguardhome.clients has duplicate ids: ${toString ids}";
        })
      ];

      # Built-in rewrites, merged with any set by the host
      services.native.adguardhome.dnsRewrites = [
        { domain = "adguard.local"; answer = cfg.bindAddress; }
      ] ++ lib.optional (primaryDomain != "") {

        # Split-horizon: LAN clients (using this AdGuard instance as DNS) resolve
        # *.<primary domain> straight to Caddy on the LAN instead of the public Pangolin IP the
        # Cloudflare wildcard record points at — see services.native.caddy's deployment notes.
        # Keeps every Caddy-fronted service reachable from the LAN regardless of whether
        # it also has a Pangolin Resource exposing it publicly yet.
        domain = "*.${primaryDomain}";
        answer = cfg.bindAddress;
      };

      # Upstream's `openFirewall` only opens `cfg.port` (the HTTP admin port, TCP-only) - it does
      # NOT open DNS's port 53 despite what the option name might suggest. DNS needs both UDP (the
      # common case) and TCP (large/truncated responses), opened explicitly here instead.
      networking.firewall.allowedTCPPorts = [ 53 ];
      networking.firewall.allowedUDPPorts = [ 53 ];

      # The HTTP admin port is left closed when fronted by services.native.caddy on the same host -
      # Caddy reaches it via bindAddress (local traffic, not subject to the firewall), and LAN clients
      # go through Caddy's TLS instead of hitting AdGuard's HTTP port directly.
      services.adguardhome = {
        enable = true;
        host = cfg.bindAddress;
        port = cfg.port;
        openFirewall = !cfg.caddy; # opens only the HTTP admin port - see note above
        settings = {
          theme = "dark";
          dns = {
            bind_hosts = [
              cfg.bindAddress
            ];
            ratelimit = 0;
            upstream_dns = [
              "https://dns.cloudflare.com/dns-query"
            ];
            bootstrap_dns = [
              "1.1.1.1"
              "9.9.9.10"
            ];
            fallback_dns = [
              "https://dns10.quad9.net/dns-query"
            ];

            # Don't even bother logging just drop them. Setting this replaces AdGuard's defaults, so
            # its fingerprinting-query defaults are repeated here
            blocked_hosts = [
              "version.bind"
              "id.server"
              "hostname.bind"
              "connections.brother.com" # phone home for brother printers
            ];
          };
          filters = [
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
              name = "AdGuard DNS filter";
              id = 1;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_59.txt";
              name = "AdGuard DNS Popup Hosts filter";
              id = 1768503590;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_53.txt";
              name = "AWAvenue Ads Rule";
              id = 1768503591;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_4.txt";
              name = "Dan Pollock's List";
              id = 1768503592;
            }
            {
              enabled = false;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_51.txt";
              name = "HaGeZi's Pro++ Blocklist";
              id = 1768503595;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt";
              name = "Malicious URL Blocklist (URLHaus)";
              id = 1768503598;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_27.txt";
              name = "OISD Blocklist Big";
              id = 1768503599;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_50.txt";
              name = "uBlock₀ filters – Badware risks";
              id = 1768503600;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_3.txt";
              name = "Peter Lowe's Blocklist";
              id = 1768503601;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt";
              name = "The Big List of Hacked Malware Web Sites";
              id = 1768503602;
            }
            {
              enabled = false;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_69.txt";
              name = "ShadowWhisperer Tracking List";
              id = 1768503603;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_31.txt";
              name = "Stalkerware Indicators List";
              id = 1768503604;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_33.txt";
              name = "Steven Black's List";
              id = 1768503605;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_42.txt";
              name = "ShadowWhisperer's Malware List";
              id = 1768503606;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_39.txt";
              name = "Dandelion Sprout's Anti Push Notifications";
              id = 1768503607;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_6.txt";
              name = "Dandelion Sprout's Game Console Adblock List";
              id = 1768503608;
            }

            # Specific allow list for allowing some affiliate referral tracking to keep things working
            # for shopping sites.
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_45.txt";
              name = "HaGeZi's Allowlist Referral";
              id = 1768503609;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_10.txt";
              name = "Scam Blocklist by DurableNapkin";
              id = 1768503610;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_46.txt";
              name = "HaGeZi's Anti-Piracy Blocklist";
              id = 1768503611;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_18.txt";
              name = "Phishing Army";
              id = 1768503612;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_67.txt";
              name = "HaGeZi's Apple Tracker Blocklist";
              id = 1768503613;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_8.txt";
              name = "NoCoin Filter List";
              id = 1768503614;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_47.txt";
              name = "HaGeZi's Gambling Blocklist";
              id = 1768503615;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_66.txt";
              name = "HaGeZi's OPPO & Realme Tracker Blocklist";
              id = 1768503616;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_68.txt";
              name = "HaGeZi's URL Shortener Blocklist";
              id = 1768503617;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_44.txt";
              name = "HaGeZi's Threat Intelligence Feeds";
              id = 1768503619;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_56.txt";
              name = "HaGeZi's The World's Most Abused TLDs";
              id = 1768503621;
            }
            {
              enabled = false;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_52.txt";
              name = "HaGeZi's Encrypted DNS/VPN/TOR/Proxy Bypass";
              id = 1768503624;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_54.txt";
              name = "HaGeZi's DynDNS Blocklist";
              id = 1768503626;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_7.txt";
              name = "Perflyst and Dandelion Sprout's Smart-TV Blocklist";
              id = 1768503627;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_57.txt";
              name = "ShadowWhisperer's Dating List";
              id = 1768503628;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_71.txt";
              name = "HaGeZi's DNS Rebind Protection";
              id = 1768503629;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_62.txt";
              name = "Ukrainian Security Filter";
              id = 1768503630;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_55.txt";
              name = "HaGeZi's Badware Hoster Blocklist";
              id = 1768503631;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_30.txt";
              name = "Phishing URL Blocklist (PhishTank and OpenPhish)";
              id = 1768503632;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_12.txt";
              name = "Dandelion Sprout's Anti-Malware List";
              id = 1768503633;
            }
            {
              enabled = true;
              url = "https://v.firebog.net/hosts/Easylist.txt";
              name = "EasyList";
              id = 1768503634;
            }
            {
              enabled = true;
              url = "https://v.firebog.net/hosts/Easyprivacy.txt";
              name = "EasyPrivacy";
              id = 1768503635;
            }
            {
              enabled = true;
              url = "https://blocklistproject.github.io/Lists/adguard/porn-ags.txt";
              name = "Blocklist adult content";
              id = 1768503636;
            }
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_24.txt";
              name = "1Hosts (Lite)";
              id = 1768503639;
            }
          ];
          whitelist_filters = [
            {
              enabled = true;
              url = "https://raw.githubusercontent.com/phR0ze/adguard-lists/refs/heads/main/allow/allow.txt";
              name = "phR0ze allows";
              id = 1757123023;
            }
          ];
          user_rules = [
            "# Block Ads/Tracking not blocked by AdGuard"
            "||adservice.google.*^$important"
            "||adsterra.com^$important"
            "||amplitude.com^$important"
            "||analytics.edgekey.net^$important"
            "||analytics.twitter.com^$important"
            "||app.adjust.*^$important"
            "||app.*.adjust.com^$important"
            "||doubleclick.net^$important"
            "||googleadservices.com^$important"
            "||guce.advertising.com^$important"
            "||metric.gstatic.com^$important"
            "||mmstat.com^$important"
            "||statcounter.com^$important"
            "# Block firefox telemetry"
            "||firefox.settings.services.mozilla.com^$important"
            "||firefox-settings-attachments.cdn.mozilla.net^$important"
            "||getpocket.cdn.mozilla.net^$important"
            "# Unblock one offs"
          ]
          ++ map (d: "@@||${d}^$important") (cfg.unblockedDomains
            # Never block our own Caddy-fronted services. Built from the primary domain so the zone
            # never lands in a tracked file
            ++ lib.optional (primaryDomain != "") "*.${primaryDomain}");

          filtering = {
            safe_search = safeSearch;
            rewrites = map (x: x // { enabled = true; }) cfg.dnsRewrites;
            filtering_enabled = true;
            parental_enabled = true;
            safebrowsing_enabled = true;
            protection_enabled = true;
          };
          statistics = {
            # Increase retention to 90 days
            interval = "2160h";
          };

          # Only when declared, so a host without args keeps managing clients in the web UI
          clients = lib.mkIf (cfg.clients != [ ]) {
            persistent = map toClient cfg.clients;
          };
        };
      };

      # Upstream's own preStart (adguardhome.nix) writes/yaml-merges AdGuardHome.yaml from `settings`
      # on every start, running as the service's `DynamicUser` (mutableSettings=true preserves the
      # existing `users` field across restarts since `settings` above never sets one) - patchAdminUser
      # must see that file already in place before it can (re)patch `.users` into it, so it's added as
      # its own `ExecStartPre` entry (rather than folded into the `preStart` string) with a `+` prefix:
      # that runs it as root, bypassing both `DynamicUser` (needed since the secret files below are
      # root-owned/mode 0400 - adguardhome's DynamicUser has no static name to grant read access to
      # instead) and `SystemCallFilter` (yq-go was getting killed with SIGSYS under upstream's
      # `~@privileged ~@resources` filter). `mkAfter` keeps it ordered after upstream's own
      # preStart-generated `ExecStartPre` entry, which plain list concatenation order wouldn't
      # otherwise guarantee.
      systemd.services.adguardhome.serviceConfig.ExecStartPre = lib.mkAfter [ "+${patchAdminUser}" ];

      # Stage runtime secrets
      secret.files = {
        ${cfg.userSecretRef} = {
          filemode = "0400";
          sopsFile = cfg.sopsFile;
          restartUnits = [ "adguardhome.service" ];
        };
        ${cfg.htpasswdSecretRef} = {
          filemode = "0400";
          sopsFile = cfg.sopsFile;
          restartUnits = [ "adguardhome.service" ];
        };
      };
    }

    # Nightly stop -> rsync -> start snapshot of the data dir
    # - Runs as root since it has to stop/start the service. Upstream uses DynamicUser so the data
    #   actually lives in /var/lib/private/AdGuardHome; the trailing slash makes rsync follow the
    #   /var/lib/AdGuardHome symlink. There's no static user to own the backup, so it's root-only
    # - The EXIT trap restarts adguardhome even if rsync fails, but only if it was running beforehand
    # - No wantedBy on the service itself so it never fires (and takes DNS down) at boot
    (lib.mkIf (cfg.backupDir != null) (let
      dataDir = "/var/lib/AdGuardHome";
      backupDir = "${cfg.backupDir}/adguardhome";
    in {
      assertions = [
        { assertion = !(lib.hasPrefix "${dataDir}/" "${backupDir}/")
            && !(lib.hasPrefix "/var/lib/private/AdGuardHome/" "${backupDir}/");
          message = "services.native.adguardhome.backupDir must be outside ${dataDir}"; }
      ];

      # Have services.native.alerts watch this backup
      services.native.alerts.enable = lib.mkDefault true;
      services.native.alerts.backup.services = [ "adguardhome" ];

      systemd.tmpfiles.settings."10-adguardhome-backup".${backupDir}.d = {
        user = "root";
        group = "root";
        mode = "0700";
      };

      systemd.services.backup-adguardhome = {
        description = "Backup AdGuard Home data dir";
        path = [ pkgs.rsync config.systemd.package ];
        serviceConfig.Type = "oneshot";
        script = ''
          set -euo pipefail
          if systemctl is-active --quiet adguardhome.service; then
            trap 'systemctl start adguardhome.service' EXIT
            systemctl stop adguardhome.service
          fi
          rsync -a --delete --exclude=/data/filters/ ${dataDir}/ ${backupDir}/
        '';
      };

      systemd.timers.backup-adguardhome = {
        description = "Backup AdGuard Home nightly";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.backupTime;
          Persistent = true;
        };
      };
    }))

    # Add a caddy proxy config for DNS subdomain resolution. AdGuard listens on bindAddress rather
    # than loopback, so the proxy has to target that instead of caddy_proxy's 127.0.0.1 default.
    (lib.mkIf cfg.caddy {
      services.native.caddy.enable = lib.mkDefault true;
      services.native.caddy.domains = f.caddyProxies cfg [ { inherit (cfg) subdomain port; host = cfg.bindAddress; } ];
      assertions = [ (f.caddyDomainsAssert "native.adguardhome" cfg) ];
    })
  ]);
}
