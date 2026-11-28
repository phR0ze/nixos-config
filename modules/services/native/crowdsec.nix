# CrowdSec configuration
#
# ### Purpose
# - Generic detection engine + firewall bouncer wiring, shared by any service that wants to feed it
#   acquisitions/scenarios/collections (e.g. services.native.sshd contributes SSH-specific detection
#   on top of this when its own harden option is enabled)
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.services.native.crowdsec;
  bouncerCfg = config.services.crowdsec-firewall-bouncer;

  # Split bans: see the `sshPorts` option and the nftables tables below
  sshSplit = cfg.sshPorts != [ ];
  sshBouncer = "crowdsec-firewall-bouncer-ssh";
  sshSet4 = "crowdsec-ssh";
  sshSet6 = "crowdsec6-ssh";

  # Registers a bouncer with the local LAPI, storing its key in /var/lib/<name>-register. Replaces
  # upstream's broken crowdsec-firewall-bouncer-register.service: same idempotent register-once
  # logic, but calling the working `cscli` wrapper instead of the raw, unconfigured package binary.
  # An interrupted run can leave the name registered with its api-key file lost, and `cscli
  # bouncers add` refuses a duplicate name with no --force, so recovery is delete-then-recreate.
  mkBouncerRegister = name: {
    description = "Register ${name} to the local CrowdSec service";
    after = [ "crowdsec.service" ];
    wants = [ "crowdsec.service" ];
    # The `cscli` wrapper only lands on environment.systemPackages, not any package we can
    # reference directly - config.system.path (not just pkgs.jq) is needed for a systemd unit to
    # find it.
    path = [ pkgs.jq config.system.path ];
    script = ''
      set -euo pipefail
      apiKeyFile=/var/lib/${name}-register/api-key.cred
      if cscli bouncers list --output json | jq -e --arg n ${name} 'any(.[]; .name == $n)' >/dev/null \
          && [ -s "$apiKeyFile" ]; then
        exit 0
      fi
      cscli bouncers delete --ignore-missing -- ${name} >/dev/null
      rm -f "$apiKeyFile"
      if ! cscli bouncers add --output raw -- ${name} >"$apiKeyFile"; then
        rm -f "$apiKeyFile"
        exit 1
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      User = config.services.crowdsec.user;
      Group = config.services.crowdsec.group;
      StateDirectory = "${name}-register";
      UMask = "0077";
    };
  };

  # Hardening on top of upstream's sandbox, shared by both firewall bouncers
  bouncerHardening = {
    # The bouncer exits fatally ("bouncer stream halted") if crowdsec's LAPI isn't listening yet,
    # e.g. while crowdsec.service is still retrying its boot-time hub update above. Upstream sets
    # no Restart=, so keep retrying until the LAPI comes up.
    Restart = "on-failure";
    RestartSec = 30;

    # CAP_NET_ADMIN manipulates the nftables ruleset via netlink - cannot be capability-stripped
    # like the engine (crowdsec.service). CAP_NET_RAW is NOT needed here: upstream's module only adds it for
    # the legacy iptables/ipset mode (raw packet-filter socket access for the iptables binary),
    # which this host no longer uses now that `networking.nftables.enable` is on.
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    ProtectKernelTunables = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    ProtectClock = true;
    ProtectHostname = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    RestrictRealtime = true;
    MemoryDenyWriteExecute = true;
    CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
  };

  # One family's ban sets plus the chain that drops them. Hooked at prerouting, ahead of netavark's
  # DNAT (dstnat, -100), so it covers the host's own ports and container-published ones (e.g.
  # Pangolin's 443 and WireGuard), which are DNAT'd through `forward` and never reach `input`. The
  # source address is never rewritten there, so this matches the same sets the bouncers fill.
  # With `sshPorts` set, the main set skips those ports and the SSH set covers every port.
  mkBanTable = { family, addrType, allSet, sshSet }: ''
    set ${allSet} {
      type ${addrType}
      flags timeout
    }
    ${lib.optionalString sshSplit ''
      set ${sshSet} {
        type ${addrType}
        flags timeout
      }
    ''}
    chain crowdsec-prerouting {
      type filter hook prerouting priority mangle + 5; policy accept;
      ${lib.optionalString sshSplit ''
        ${family} saddr @${sshSet} drop
        tcp dport { ${lib.concatMapStringsSep ", " toString cfg.sshPorts} } return
      ''}
      ${family} saddr @${allSet} drop
    }
  '';

  # Upstream's unit, rebuilt for the SSH bouncer (nixpkgs only supports one instance)
  sshBouncerConfig = "/run/${sshBouncer}/config.yaml";
  sshBouncerSettings = lib.recursiveUpdate bouncerCfg.settings {
    blacklists_ipv4 = sshSet4;
    blacklists_ipv6 = sshSet6;
    # Case-insensitive substring of the decision's scenario, OR'd across entries, applied by
    # the LAPI to the decision stream (new and deleted alike). `ssh` covers the hub's
    # crowdsecurity/ssh-* scenarios, local/ssh-bf-tight and community (CAPI) SSH decisions;
    # `iptables-scan` covers crowdsecurity/iptables-scan-multi_ports (port scans). Web
    # scenarios (http-*, appsec, vpatch-*, CRS anomaly scores, crs-probing, CVEs) match none.
    # No spaces: the LAPI splits on "," without trimming.
    scenarios_containing = [ "ssh" "iptables-scan" ];
  };
  sshBouncerGenConfig = pkgs.writeShellScript "${sshBouncer}-config" ''
    set -euo pipefail
    umask 077
    cp ${(pkgs.formats.yaml { }).generate "${sshBouncer}.yaml" sshBouncerSettings} ${sshBouncerConfig}
    chmod 0600 ${sshBouncerConfig}
    ${lib.getExe pkgs.replace-secret} '@API_KEY_FILE@' "$CREDENTIALS_DIRECTORY/API_KEY_FILE" ${sshBouncerConfig}
  '';
in
{
  options.services.native.crowdsec = {
    enable = lib.mkEnableOption "Install and configure the CrowdSec detection engine and firewall bouncer";

    allowlist = lib.mkOption {
      description = ''
        Trusted management IPs/CIDRs that CrowdSec should never ban, regardless of what triggers a
        detection. Without this, a flaky VPN/jump-host reconnect loop (or any other false positive)
        can firewall-bounce you out of your own box.
      '';
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "203.0.113.7" "198.51.100.0/24" ];
    };

    sshPorts = lib.mkOption {
      description = ''
        SSH ports exempt from bans that aren't SSH-related. With this empty, every ban drops the
        source on every port. Set, a second firewall bouncer fills a separate set with only
        SSH and port-scan decisions (local and community), dropped on every port, while the
        main set (every decision) skips these ports. A false positive from a web app then
        bans the user from the web apps but still lets them SSH in and lift it with
        `cscli decisions delete`. Forwarded from services.native.sshd's harden option.
      '';
      type = lib.types.listOf lib.types.port;
      default = [ ];
      example = [ 2222 ];
    };

    sopsFile = lib.mkOption {
      description = ''
        Path to the host's `secrets.enc.yaml`, decrypted at activation time by sops-nix to source
        the CrowdSec Central API (CAPI) credentials. Defaults to `config.host.secrets`. Leave
        null to skip CAPI enrollment entirely - `capiCredentialsFile` then also stays null, so
        this host only bans IPs it has personally observed attacking it.
      '';
      type = lib.types.nullOr lib.types.path;
    };

    capiCredentialsFile = lib.mkOption {
      description = ''
        Path to CrowdSec's Central API (CAPI) credentials file, enrolling this machine in
        CrowdSec's crowd-sourced blocklist (consuming other users' bans, not just your own local
        detections). Obtain it with a one-time `cscli capi register` run, then manage the
        resulting file via runtime secrets (sops-nix), never the Nix store. Sourced from
        `secret.files."crowdsec/capiCredentials"` (keyed off `sopsFile` above) whenever `sopsFile`
        is set; stays null otherwise.
      '';
      type = lib.types.nullOr lib.types.path;
      default = if cfg.sopsFile != null then config.secret.files."crowdsec/capiCredentials".path else null;
    };

    console.enroll = lib.mkOption {
      description = ''
        One-time enrollment in the CrowdSec Console (app.crowdsec.net), which lets this engine
        subscribe to the Console's extra blocklists on top of the community blocklist. Reads the
        enroll key from `crowdsec/consoleEnrollKey` in `sopsFile`; accept the engine in the Console
        afterwards. The console.yaml `share_*` options stay at their false defaults. On by default
        whenever CrowdSec is enabled; set false for a host without a consoleEnrollKey.
      '';
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = cfg.console.enroll -> cfg.sopsFile != null;
        message = "services.native.crowdsec.console.enroll requires 'sopsFile' for crowdsec/consoleEnrollKey";
      }
      # The LAPI listens on 0.0.0.0 (see listen_uri below), so the NixOS firewall is the only
      # thing keeping 8080 off the public interface
      { assertion = config.networking.firewall.enable;
        message = "services.native.crowdsec requires networking.firewall.enable - its LAPI listens on 0.0.0.0:8080 and relies on the firewall to stay private";
      }
    ];

    secret.files."crowdsec/consoleEnrollKey" = lib.mkIf cfg.console.enroll {
      sopsFile = cfg.sopsFile;
      user = config.services.crowdsec.user;
      group = config.services.crowdsec.group;
    };

    secret.files."crowdsec/capiCredentials" = lib.mkIf (cfg.sopsFile != null) {
      sopsFile = cfg.sopsFile;
      user = config.services.crowdsec.user;
      group = config.services.crowdsec.group;
      # crowdsec authenticates to the CAPI at startup, so a re-registered credentials file only
      # takes effect once the running daemon is restarted
      restartUnits = [ "crowdsec.service" ];
    };

    # crowdsec-firewall-bouncer manages its ruleset via nftables/netlink on this host (mode follows
    # `networking.nftables.enable`), which needs `nf_tables` loaded - preloaded centrally by
    # modules/devices/kernel.nix's harden block (see its comment for why it's gathered there
    # rather than duplicated per-module).

    services.crowdsec = {
      enable = true;
      settings.config.api.server.enable = true;    # local LAPI for the bouncer to query decisions from

      # The single LAPI for every CrowdSec component on the host, including container agents and
      # bouncers (e.g. services.oci.pangolin's), which reach it over their podman bridge - so it
      # can't stay on loopback. networking.firewall keeps 8080 closed on every other interface;
      # a module that needs it opens it on its own bridge only.
      settings.config.api.server.listen_uri = "0.0.0.0:8080";
      autoUpdateService = true;                    # daily `cscli hub update` to pick up new/CVE scenarios

      # Local LAPI machine credentials, auto-provisioned by `cscli machine add --auto` on first
      # activation (see upstream's crowdsec-setup.service) whenever this file doesn't exist yet -
      # required any time api.server.enable is set, regardless of the CAPI/hosted-console settings.
      settings.config.api.client.credentials_path = "/var/lib/crowdsec/state/local_api_credentials.yaml";

      # Data location (db, hub, data files) is set explicitly rather than following upstream's
      # default, so a default change can never silently strand the database. Upstream derives its
      # sandbox paths and tmpfiles dirs from these, so overriding them is fully supported. Its
      # 26.11 rework moved the default from /var/lib/crowdsec/state to /var/lib/crowdsec/data with
      # no migration, and an upgraded host came up on an empty database: every machine, bouncer
      # key, decision and the allowlist gone (hosts/vps2, 2026-11-02).
      settings.config.config_paths = {
        data_dir = "/var/lib/crowdsec/state";
        hub_dir = "/var/lib/crowdsec/state/hub";
        index_path = "/var/lib/crowdsec/state/hub/.index.json";
      };
      settings.config.db_config.db_path = "/var/lib/crowdsec/state/crowdsec.db";

      # Without a `flush` block the LAPI never prunes its database: every alert and expired
      # decision (community blocklist refreshes included) is kept forever. Deleting an alert
      # deletes its decisions too, so max_age must stay at or above the longest ban the profiles
      # below can issue (2160h = 90d).
      settings.config.db_config.flush.max_age = "90d";

      # console.configuration.share_* are intentionally left at their false upstream defaults -
      # nothing is reported to CrowdSec's hosted console unless explicitly opted into.
      settings.config.api.server.online_client.credentials_path = cfg.capiCredentialsFile;

      # Port-scan detection against the dropped-connection logs enabled above - this is what covers
      # traffic that never touches any particular service's own logs at all. Left as the
      # `iptables` collection even under nftables mode: nftables' `log` statement reuses the same
      # netfilter LOG line format (IN=/OUT=/SRC=/DST=/...) this collection's parser expects, so the
      # kernel log source doesn't change - only re-point this at an nftables-specific collection if
      # a VM test shows this one stops matching.
      hub.collections = [ "crowdsecurity/iptables" ];

      settings = {
        acquisitions = [
          {
            source = "journalctl";
            journalctl_filter = [ "_TRANSPORT=kernel" ];   # netfilter LOG target drops land here
            labels.type = "syslog";
          }
        ];

        # Never ban our own trusted management IPs, no matter what triggers detection (e.g. a flaky
        # VPN/jump-host reconnect loop tripping a brute-force scenario against ourselves).
        # CrowdSec parses `ip` entries as bare addresses only - a CIDR there is a fatal parse error
        # at startup - so ranges have to be split out into the separate `cidr` field.
        postOverflows.s01Whitelist = lib.optional (cfg.allowlist != [ ]) {
          name = "local/whitelist-management-ips";
          description = "Whitelist trusted management IPs from bans";
          whitelist =
            let
              isCidr = lib.hasInfix "/";
            in
            {
              reason = "trusted management IP";
              ip = lib.filter (x: !isCidr x) cfg.allowlist;
              cidr = lib.filter isCidr cfg.allowlist;
            };
        };

        # Setting settings.profiles at all replaces the hub's profiles.yaml outright (it does
        # not merge). Upstream splits Ip/Range scope into two profiles since they can carry
        # different durations, but both escalate the same way here, so one profile covers both. It
        # matches every Ip/Range alert, not just upstream's `Alert.Remediation == true`, so a
        # scenario that only flags an address still bans it. This LAPI is the hub for every agent
        # (sshd, kernel port scans, Pangolin's Traefik/AppSec), so they all share it.
        #
        # Bans escalate rather than being permanent: 4h, 16h, 36h, 64h, ... (4h x n^2 for the IP's
        # nth decision in the last 30 days), so repeat offenders end up banned for long stretches
        # while one-off hits on shared carrier-NAT addresses and false positives expire on their own
        # - a single AppSec hit from a T-Mobile phone earned a 10-year ban on that shared IP under
        # the old permanent profile (hosts/vps1, 2026-10-08), and the firewall bouncer applies every
        # ban on every port. Exploit attempts no real client makes (AppSec virtual patches, CVE
        # scenarios) start at 3 days on the same curve instead.
        #
        # Both only ban an IP with no active decision. Every alert of a burst used to get its own
        # decision, and each one raised the count for the next, so one 6-second scan escalated
        # 4h -> 774400h (88 years) and left ~500 decisions for a single IP (hosts/vps1, 2026-10-10).
        # Alerts from an already-banned IP (requests in flight before the bouncers caught up) are
        # still stored and shared with CAPI, they just match no profile. The caps keep every ban
        # inside the database flush's max_age below, which deletes an alert's decisions with it.
        #
        # Lone OWASP CRS hits don't ban. The hub's crowdsecurity/crs appsec config sends an alert
        # for every out-of-band match, and its scenario is named after the request's CRS scores
        # (`anomaly score out-of-band: <category>: <n>, ..., anomaly: <total>, `). A request that
        # only trips one rule with no attack category, scoring under 8 (one critical rule is 5),
        # is a policy hit such as a disallowed content type or a scanner-like user agent, and a
        # legitimate client repeats it on every poll or retry: Pangolin's dashboard login and its
        # Android client each banned a phone on its first request (hosts/vps1, 2026-10-11). The
        # hub's crowdsecurity/crowdsec-appsec-outofband (6 out-of-band hits within ~2.5min) skips
        # banning too, since a client polling once a second reaches that on a single URL. Repeated
        # lone hits are banned instead by a scenario counting distinct URLs per IP, which only
        # probing reaches - shipped by whichever module runs CRS (services.oci.pangolin's
        # crs-probing). Requests with an attack category or several rules still ban on one hit.
        #
        # Profiles only apply to local alerts: community blocklist (CAPI) and Console blocklist
        # decisions keep the durations CrowdSec sets. Hub scenarios stay unmodified, which is what
        # CAPI requires to count our signals.
        profiles = [
          {
            name = "exploit_ban";
            filters = [ ''Alert.GetScope() == "Ip" && Alert.GetScenario() matches "(?i)^crowdsecurity/vpatch-|^crowdsecurity/appsec-vpatch$|cve" && GetActiveDecisionsCount(Alert.GetValue()) == 0'' ];
            decisions = [
              { type = "ban"; duration = "72h"; } # fallback if duration_expr fails to evaluate
            ];
            duration_expr = "let n = GetDecisionsSinceCount(Alert.GetValue(), '30d'); Sprintf('%dh', min(72 * (n + 1) * (n + 1), 2160))";
            on_success = "break";
          }
          {
            name = "escalating_ban";
            filters = [ ''Alert.GetScope() in ["Ip", "Range"] && GetActiveDecisionsCount(Alert.GetValue()) == 0 && !(Alert.GetScenario() matches "^anomaly score out-of-band: anomaly: [1-7], ?$" || Alert.GetScenario() == "crowdsecurity/crowdsec-appsec-outofband")'' ];
            decisions = [
              { type = "ban"; duration = "4h"; } # fallback if duration_expr fails to evaluate
            ];
            duration_expr = "let n = GetDecisionsSinceCount(Alert.GetValue(), '30d'); Sprintf('%dh', min(4 * (n + 1) * (n + 1), 720))";
            on_success = "break";
          }
        ];
      };
    };

    services.crowdsec-firewall-bouncer = {
      enable = true;   # applies CrowdSec's ban decisions via iptables

      # registerBouncer.enable is broken upstream: it shells out to cscli's raw binary with no `-c`
      # flag, so it never finds crowdsec's actual (store-path) config and always errors "no
      # configuration file found" (same class of bug as nixpkgs#459224). Registered manually below
      # instead, via the working `cscli` wrapper services.crowdsec puts on PATH.
      registerBouncer.enable = false;
      secrets.apiKeyPath = "/var/lib/crowdsec-firewall-bouncer-register/api-key.cred";

      # Upstream derives this from the LAPI's listen_uri, which is 0.0.0.0 above
      settings.api_url = "http://127.0.0.1:8080";

      # Upstream polls every 10s, but web-exploit scanners finish a burst of hundreds of requests
      # in 6-13s, so bans only landed after the scan was over (hosts/vps1, 2026-10-10). Polling a
      # loopback LAPI every 2s is cheap.
      settings.update_frequency = "2s";
    };

    # nftables.service reloads (every switch that changes a rule) delete and recreate each declared
    # table, emptying the bouncers' ban sets. A bouncer doesn't notice and never re-adds a decision
    # it already pushed, and its PartOf only follows stop/restart, not reload - after one reload
    # 13.5k active bans stayed missing from the firewall for two days (hosts/vps1, 2026-10-11). A
    # restart re-pulls every active decision.
    systemd.services.nftables.serviceConfig.ExecReload = lib.mkAfter [
      "${config.systemd.package}/bin/systemctl --no-block try-restart crowdsec-firewall-bouncer.service${lib.optionalString sshSplit " ${sshBouncer}.service"}"
    ];

    # nixpkgs' set-only ruleset only hooks `input`, but container-published ports (e.g. Pangolin's
    # 443 and WireGuard ports) are DNAT'd and go through `forward` instead, so a ban never reached
    # them. Upstream's own bouncer hooks both `input` and `forward`. Our own tables replace
    # nixpkgs' (see mkBanTable), dropping banned sources at prerouting to cover both in one place.
    #
    # Every decision used to drop its source on every port, so a false positive from one of our own
    # web apps also locked the user out of SSH, e.g. deleting 3 Vaultwarden items in a row
    # (hosts/vps1, 2026-11-28). With `sshPorts` set, SSH and port-scan bans land in a second set
    # (filled by ${sshBouncer}) that covers every port, and the main set skips the SSH ports.
    # An IP banned only for web activity can still reach sshd, where it still faces key-only auth,
    # MaxAuthTries, the per-source rate limit, and an SSH ban on its first failed logins. Both
    # bouncers share each table in set-only mode; each only fills, and on stop empties, its own set.
    services.crowdsec-firewall-bouncer.createRulesets = false;
    networking.nftables.tables = {
      ${bouncerCfg.settings.nftables.ipv4.table} = lib.mkIf bouncerCfg.settings.nftables.ipv4.enabled {
        family = "ip";
        content = mkBanTable {
          family = "ip"; addrType = "ipv4_addr";
          allSet = bouncerCfg.settings.blacklists_ipv4; sshSet = sshSet4;
        };
      };
      ${bouncerCfg.settings.nftables.ipv6.table} = lib.mkIf bouncerCfg.settings.nftables.ipv6.enabled {
        family = "ip6";
        content = mkBanTable {
          family = "ip6"; addrType = "ipv6_addr";
          allSet = bouncerCfg.settings.blacklists_ipv6; sshSet = sshSet6;
        };
      };
    };

    systemd.services.crowdsec-firewall-bouncer-register = mkBouncerRegister "crowdsec-firewall-bouncer";
    systemd.services."${sshBouncer}-register" = lib.mkIf sshSplit (mkBouncerRegister sshBouncer);

    # Same shape as nixpkgs' crowdsec-firewall-bouncer.service, which only supports one instance
    systemd.services.${sshBouncer} = lib.mkIf sshSplit {
      description = "CrowdSec Firewall Bouncer for SSH and port-scan bans";
      partOf = [ "nftables.service" ];
      after = [ "nftables.service" "crowdsec.service" "${sshBouncer}-register.service" ];
      wants = [ "nftables.service" "crowdsec.service" ];
      requires = [ "${sshBouncer}-register.service" ];
      serviceConfig = bouncerHardening // {
        Type = "notify";
        ExecStartPre = [ sshBouncerGenConfig "${lib.getExe bouncerCfg.package} -c ${sshBouncerConfig} -t" ];
        ExecStart = "${lib.getExe bouncerCfg.package} -c ${sshBouncerConfig}";
        LimitNOFILE = 65536;
        KillMode = "mixed";
        LoadCredential = "API_KEY_FILE:/var/lib/${sshBouncer}-register/api-key.cred";
        DynamicUser = true;
        RuntimeDirectory = sshBouncer;
        AmbientCapabilities = [ "CAP_NET_ADMIN" ];
        PrivateDevices = true;
        ProcSubset = "pid";
        ProtectProc = "invisible";
        ProtectKernelModules = true;
        RestrictNamespaces = true;
        SystemCallArchitectures = "native";
        RestrictAddressFamilies = [ "AF_NETLINK" "AF_UNIX" "AF_INET" "AF_INET6" ];
        SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" ];
        UMask = "0077";
      };
    };

    # crowdsec's startup hub update and CAPI login need the network, so start the engine and its
    # bouncers once it's up, after boot (see devices.network.onlineServices). The register units are
    # listed too, as their `wants` would otherwise pull crowdsec back into boot.
    devices.network.onlineServices = [
      "crowdsec" "crowdsec-firewall-bouncer" "crowdsec-firewall-bouncer-register"
      "crowdsec-allowlist-sync"
    ] ++ lib.optional cfg.console.enroll "crowdsec-console-enroll"
      ++ lib.optionals sshSplit [ sshBouncer "${sshBouncer}-register" ];

    # The postoverflow whitelist above only applies to this host's own agent. A centralized
    # allowlist is enforced by the LAPI itself, so it also covers every remote agent (e.g.
    # Pangolin's Traefik/AppSec container), AppSec requests, and community/Console blocklist
    # decisions. Reconciled to `allowlist` on every start: missing entries added, stale ones
    # removed. The postoverflow stays as the static fallback while this hasn't run yet.
    systemd.services.crowdsec-allowlist-sync = {
      description = "Sync the CrowdSec centralized management allowlist";
      after = [ "crowdsec.service" ];
      wants = [ "crowdsec.service" ];
      partOf = [ "crowdsec.service" ];
      path = [ pkgs.jq config.system.path ];
      script = ''
        set -euo pipefail
        name=management
        for i in $(seq 1 30); do
          cscli lapi status >/dev/null 2>&1 && break
          sleep 2
        done
        if ! cscli allowlists list -o json | jq -e --arg n "$name" 'any(.[]?; .name == $n)' >/dev/null; then
          cscli allowlists create "$name" -d "Trusted management IPs, never banned"
        fi
        current=$(cscli allowlists inspect "$name" -o json | jq -r '.items // [] | .[].value')
        wanted=${lib.escapeShellArg (lib.concatStringsSep "\n" cfg.allowlist)}
        for v in $current; do
          grep -qxF -- "$v" <<<"$wanted" || cscli allowlists remove "$name" "$v"
        done
        for v in $wanted; do
          grep -qxF -- "$v" <<<"$current" || cscli allowlists add "$name" "$v" -d "services.native.crowdsec.allowlist"
        done
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # oneshots never time out by default; a crowdsec that can't start would otherwise hold
        # network-services.target (and a running switch) open indefinitely
        TimeoutStartSec = "5min";
        User = config.services.crowdsec.user;
        Group = config.services.crowdsec.group;
      };
    };

    # nixpkgs' own console enrollment (originally `settings.console.tokenFile`, whose guard was
    # inverted; now `settings.console.enrollKeyFile`) isn't used. Enrolled once here instead,
    # tracked by a marker file.
    #
    # A first enroll exits 1 even when it worked: cscli enrolls with the Console, then always
    # rewrites console.yaml, which is a read-only store path here. Its output can't be relied on to
    # tell the cases apart either - captured from this unit it came back empty (hosts/vm-vps1,
    # 2026-10-08). So a failure is retried once: an enrolled instance gets "already enrolled" and
    # exits 0 before touching console.yaml, and anything still failing is a real failure (bad key,
    # no network). `--disable all` keeps every console.yaml share_* option at its false default.
    systemd.services.crowdsec-console-enroll = lib.mkIf cfg.console.enroll {
      description = "Enroll this CrowdSec engine in the CrowdSec Console";
      after = [ "crowdsec.service" ];
      wants = [ "crowdsec.service" ];
      path = [ config.system.path ];
      script = ''
        set -euo pipefail
        state=/var/lib/crowdsec-console-enroll
        [ -e "$state/enrolled" ] && exit 0
        enroll() {
          cscli console enroll --disable all --name ${lib.escapeShellArg config.networking.hostName} \
            "$(cat ${config.secret.files."crowdsec/consoleEnrollKey".path})"
        }
        enroll || enroll
        touch "$state/enrolled" "$state/restart"
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # Same as crowdsec-allowlist-sync: bound the wait on a crowdsec that can't start
        TimeoutStartSec = "5min";
        User = config.services.crowdsec.user;
        Group = config.services.crowdsec.group;
        StateDirectory = "crowdsec-console-enroll";
        # A boot-time attempt can fail on DNS/network not being ready yet, same as crowdsec.service
        Restart = "on-failure";
        RestartSec = 60;
        # Enrollment only takes effect once the engine restarts (cscli's own instruction) - only
        # right after enrolling, not on every boot. `+` for the privileges to restart a unit.
        ExecStartPost = "+${pkgs.writeShellScript "crowdsec-console-enroll-restart" ''
          if [ -e /var/lib/crowdsec-console-enroll/restart ]; then
            rm -f /var/lib/crowdsec-console-enroll/restart
            ${config.systemd.package}/bin/systemctl try-restart --no-block crowdsec.service
          fi
        ''}";
      };
    };

    systemd.services.crowdsec-firewall-bouncer.requires = [ "crowdsec-firewall-bouncer-register.service" ];
    systemd.services.crowdsec-firewall-bouncer.after = [ "crowdsec-firewall-bouncer-register.service" ];

    # Upstream creates every subdirectory under /var/lib/crowdsec via tmpfiles "d" rules except the
    # root dir itself, relying on DynamicUser's chown-on-start instead. Declaring
    # `StateDirectory = "crowdsec"` to plug that gap works on first boot but regresses on the next
    # one: it disagrees with DynamicUser's persisted uid mapping (PrivateUsers = true) about
    # ownership, leaving the dir owned by the overflow uid and crowdsec-setup failing with
    # "Permission denied". Extending the same tmpfiles mechanism to the root dir avoids the clash.
    systemd.tmpfiles.settings."10-crowdsec-rootdir"."/var/lib/crowdsec".d = {
      user = config.services.crowdsec.user;
      group = config.services.crowdsec.group;
      mode = "0750";
    };

    # Upstream's crowdsec-setup only retries `cscli machine add` when local_api_credentials.yaml is
    # missing/empty, but an interrupted registration can leave the DB-side entry registered without
    # the file (or vice versa) - either half surviving alone leaves crowdsec.service permanently
    # failing with "file already exists" or "user already exists".
    #
    # Can't fix this via our own `serviceConfig.ExecStartPre` (tried `lib.mkBefore`): upstream's own
    # ExecStartPre list opens with a blank entry that wipes everything declared before it, always
    # rendered after ours regardless of mkBefore/mkAfter - and `mkAfter` doesn't help either, since
    # crowdsec-setup's own failure aborts the unit first. A separate unit ordered via
    # `before`/`requiredBy` sidesteps upstream's internal list entirely.
    #
    # So: proactively (re-)register with `--force` whenever the file isn't already valid - it covers
    # both "file exists" and "machine already exists" in one shot. Once that produces a valid file,
    # upstream's own guard just skips its own attempt as normal.
    systemd.services.crowdsec-clear-stale-lapi-creds = {
      description = "Ensure a valid CrowdSec LAPI credentials file, recovering from an interrupted registration";
      before = [ "crowdsec-setup.service" "crowdsec.service" ];
      requiredBy = [ "crowdsec-setup.service" "crowdsec.service" ];
      path = [ config.system.path ];
      serviceConfig = {
        Type = "oneshot";
        User = config.services.crowdsec.user;
        Group = config.services.crowdsec.group;
        ExecStart = toString (pkgs.writeShellScript "crowdsec-clear-stale-lapi-creds" ''
          f=/var/lib/crowdsec/state/local_api_credentials.yaml
          if [ ! -s "$f" ]; then
            cscli machine add "${config.services.crowdsec.name}" --auto --force -f "$f"
          fi
        '');
      };
    };

    # Upstream deploys every settings file (scenarios, parsers, postoverflows, ...) as a tmpfiles
    # `L+` symlink named after its content-hashed store path, but never removes the previous
    # generation's link. Any change to e.g. the allowlist above therefore leaves two files declaring
    # the same `name` side by side, and crowdsec loads whichever sorts first ("multiple
    # postoverflows named ...: ignoring ..."), possibly the stale one. Prune any store-path symlink
    # under /etc/crowdsec that the current generation's tmpfiles rules no longer declare. Hub items
    # are symlinks into /var/lib/crowdsec, never /nix/store, so they're left alone.
    # Upstream writes profiles.yaml as a tmpfiles `f+` rule with the YAML inline as its argument,
    # and tmpfiles expands `%` specifiers there: the profiles' `Sprintf('%dh', ...)` hits `%d`
    # (credentials dir, "Invalid slot" outside a unit), so the rule is skipped and profiles.yaml
    # is never written. Link a store file instead, which tmpfiles never expands.
    systemd.tmpfiles.settings."10-crowdsec".${config.services.crowdsec.settings.config.api.server.profiles_path} =
      lib.mkForce {
        "L+".argument = toString (pkgs.writeText "crowdsec-profiles.yaml"
          (lib.concatMapStringsSep "\n---\n" (lib.generators.toYAML { })
            config.services.crowdsec.settings.profiles));
      };

    systemd.services.crowdsec-prune-stale-links = {
      description = "Remove CrowdSec local config symlinks left behind by previous generations";
      before = [ "crowdsec.service" ];
      requiredBy = [ "crowdsec.service" ];
      after = [ "systemd-tmpfiles-setup.service" "systemd-tmpfiles-resetup.service" ];
      serviceConfig.Type = "oneshot";
      script =
        let
          # Matches any symlink rule type (L, L+, ...) rather than one spelling: upstream's 26.11
          # rework renamed `link` to `"L+"`, which left this list empty and pruned every link,
          # config.yaml included. The assert fails the build instead of repeating that silently.
          expected = lib.attrNames (lib.filterAttrs (_: v: lib.any (lib.hasPrefix "L") (lib.attrNames v))
            config.systemd.tmpfiles.settings."10-crowdsec");
        in
        assert lib.assertMsg (lib.elem "/etc/crowdsec/config.yaml" expected)
          "crowdsec-prune-stale-links: upstream tmpfiles no longer declares /etc/crowdsec/config.yaml as a symlink, update the filter";
        ''
          declare -A expected=(${lib.concatMapStringsSep " " (p: "[${lib.escapeShellArg p}]=1") expected})
          find /etc/crowdsec -type l -lname '/nix/store/*' -print0 | while IFS= read -r -d "" link; do
            if [ -z "''${expected[$link]:-}" ]; then
              echo "removing stale $link -> $(readlink "$link")"
              rm -f -- "$link"
            fi
          done
        '';
    };

    # Never serve the 0.0.0.0 LAPI without the firewall in place: if the ruleset fails to load at
    # boot, or nftables.service is stopped (which flushes it), crowdsec doesn't start or is stopped
    # with it. A switch only reloads nftables.service, which doesn't propagate, so firewall changes
    # don't restart crowdsec. systemd's IPAddressAllow/Deny can't do this job: it filters by
    # remote address in both directions, so it would also cut off the CAPI and hub.
    systemd.services.crowdsec.requires = [ "nftables.service" ];
    systemd.services.crowdsec.after = [ "nftables.service" ];

    # crowdsec-setup runs `cscli hub update`, which needs DNS. network-online only means a link is
    # routable, not that the resolver answers yet, so that lookup can still fail ("Temporary failure
    # in name resolution") and upstream gives the oneshot no Restart=, leaving it failed for good
    # (hosts/vm-vps1 testing, 2026-10-07). Retry until DNS is up; 60s spacing never trips the
    # default start limit. crowdsec.service itself already has upstream's Restart = "always".
    systemd.services.crowdsec-setup.serviceConfig = {
      Restart = "on-failure";
      RestartSec = 60;
    };

    # Hardening on top of upstream's own sandbox. Upstream sets ProtectControlGroups = "strict",
    # ProtectHostname = "true:<name>" and ProtectKernelLogs = false itself, so those are left to it.
    systemd.services.crowdsec.serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/var/lib/crowdsec" "/etc/crowdsec" ];
      PrivateTmp = true;
      NoNewPrivileges = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectClock = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      RestrictRealtime = true;
      # NOT MemoryDenyWriteExecute: crowdsec's regex engine (go-re2, via the wazero WASM runtime)
      # JIT-compiles to native code and needs W^X-violating executable+writable pages to do it -
      # enabling this makes crowdsec.service panic with "mmapExecutable: permission denied" on
      # every start.
      RestrictNamespaces = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_UNIX" ];
      CapabilityBoundingSet = [ "" ];   # the detection engine itself needs no special capabilities
    };

    systemd.services.crowdsec-firewall-bouncer.serviceConfig = bouncerHardening;
  };
}
