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

    console.enroll = lib.mkEnableOption ''
      one-time enrollment in the CrowdSec Console (app.crowdsec.net), which lets this engine
      subscribe to the Console's extra blocklists on top of the community blocklist. Reads the
      enroll key from `crowdsec/consoleEnrollKey` in `sopsFile`; accept the engine in the Console
      afterwards. The console.yaml `share_*` options stay at their false defaults
    '';
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
      settings.general.api.server.enable = true;   # local LAPI for the bouncer to query decisions from

      # The single LAPI for every CrowdSec component on the host, including container agents and
      # bouncers (e.g. services.oci.pangolin's), which reach it over their podman bridge - so it
      # can't stay on loopback. networking.firewall keeps 8080 closed on every other interface;
      # a module that needs it opens it on its own bridge only.
      settings.general.api.server.listen_uri = "0.0.0.0:8080";
      autoUpdateService = true;                    # daily `cscli hub update` to pick up new/CVE scenarios

      # Local LAPI machine credentials, auto-provisioned by `cscli machine add --auto` on first
      # activation (see the crowdsec module's ExecStartPre) whenever this file doesn't exist yet -
      # required any time api.server.enable is set, regardless of the CAPI/hosted-console settings.
      settings.lapi.credentialsFile = "/var/lib/crowdsec/state/local_api_credentials.yaml";

      # console.configuration.share_* are intentionally left at their false upstream defaults -
      # nothing is reported to CrowdSec's hosted console unless explicitly opted into.
      settings.capi.credentialsFile = cfg.capiCredentialsFile;

      # Port-scan detection against the dropped-connection logs enabled above - this is what covers
      # traffic that never touches any particular service's own logs at all. Left as the
      # `iptables` collection even under nftables mode: nftables' `log` statement reuses the same
      # netfilter LOG line format (IN=/OUT=/SRC=/DST=/...) this collection's parser expects, so the
      # kernel log source doesn't change - only re-point this at an nftables-specific collection if
      # a VM test shows this one stops matching.
      hub.collections = [ "crowdsecurity/iptables" ];

      localConfig = {
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

        # Setting localConfig.profiles at all replaces the hub's profiles.yaml outright (it does
        # not merge). Upstream splits Ip/Range scope into two profiles since they can carry
        # different durations, but both use the same permanent duration here, so one profile
        # covers both. It matches every Ip/Range alert, not just upstream's
        # `Alert.Remediation == true`, so a scenario that only flags an address still bans it.
        # This LAPI is the hub for every agent (sshd, kernel port scans, Pangolin's Traefik/AppSec),
        # so they all get the same permanent ban. Profiles only apply to local alerts: community
        # blocklist (CAPI) and Console blocklist decisions keep the durations CrowdSec sets.
        # Hub scenarios stay unmodified, which is what CAPI requires to count our signals.
        profiles = [
          {
            name = "permanent_ban";
            filters = [ ''Alert.GetScope() in ["Ip", "Range"]'' ];
            decisions = [
              { type = "ban"; duration = "87600h"; } # ~10 years - effectively permanent
            ];
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
    };

    # nixpkgs' set-only ruleset only hooks `input`, but container-published ports (e.g. Pangolin's
    # 443 and WireGuard ports) are DNAT'd and go through `forward` instead, so a ban never reached
    # them. Upstream's own bouncer hooks both `input` and `forward`. Dropping banned sources at
    # prerouting covers both in one place, before netavark's DNAT (dstnat, -100). The source
    # address is never rewritten there, so this matches the same set the bouncer fills.
    networking.nftables.tables.${config.services.crowdsec-firewall-bouncer.settings.nftables.ipv4.table}.content = lib.mkAfter ''
      chain crowdsec-prerouting {
        type filter hook prerouting priority mangle + 5; policy accept;
        ip saddr @${config.services.crowdsec-firewall-bouncer.settings.blacklists_ipv4} drop
      }
    '';

    # Replaces upstream's broken crowdsec-firewall-bouncer-register.service (see comment above) -
    # same idempotent register-once-then-verify logic, just calling the working `cscli` wrapper
    # instead of the raw, unconfigured package binary.
    systemd.services.crowdsec-firewall-bouncer-register = {
      description = "Register the CrowdSec Firewall Bouncer to the local CrowdSec service";
      after = [ "crowdsec.service" ];
      wants = [ "crowdsec.service" ];
      # The `cscli` wrapper only lands on environment.systemPackages, not any package we can
      # reference directly - config.system.path (not just pkgs.jq) is needed for a systemd unit to
      # find it.
      path = [ pkgs.jq config.system.path ];
      # Same stale-registration hazard as crowdsec-clear-stale-lapi-creds below, but for the
      # bouncer's own DB entry: an interrupted run can leave the name registered with its api-key
      # file lost. `cscli bouncers add` refuses a duplicate name and has no --force, so recovery is
      # delete-then-recreate rather than a plain retry.
      script = ''
        set -euo pipefail
        apiKeyFile=/var/lib/crowdsec-firewall-bouncer-register/api-key.cred
        if cscli bouncers list --output json | jq -e 'any(.[]; .name == "crowdsec-firewall-bouncer")' >/dev/null \
            && [ -s "$apiKeyFile" ]; then
          exit 0
        fi
        cscli bouncers delete --ignore-missing -- crowdsec-firewall-bouncer >/dev/null
        rm -f "$apiKeyFile"
        if ! cscli bouncers add --output raw -- crowdsec-firewall-bouncer >"$apiKeyFile"; then
          rm -f "$apiKeyFile"
          exit 1
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        User = config.services.crowdsec.user;
        Group = config.services.crowdsec.group;
        StateDirectory = "crowdsec-firewall-bouncer-register";
        UMask = "0077";
      };
    };

    # crowdsec's startup hub update and CAPI login need the network, so start the engine and its
    # bouncer once it's up, after boot (see devices.network.onlineServices). The register unit is
    # listed too, as its `wants` would otherwise pull crowdsec back into boot.
    devices.network.onlineServices = [
      "crowdsec" "crowdsec-firewall-bouncer" "crowdsec-firewall-bouncer-register"
      "crowdsec-allowlist-sync"
    ] ++ lib.optional cfg.console.enroll "crowdsec-console-enroll";

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
        User = config.services.crowdsec.user;
        Group = config.services.crowdsec.group;
      };
    };

    # nixpkgs' own `settings.console.tokenFile` enrollment is unusable: its guard is inverted (it
    # only enrolls when the token file does *not* exist, then reads that missing file). Enrolled
    # once here instead, tracked by a marker file.
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
      before = [ "crowdsec.service" ];
      requiredBy = [ "crowdsec.service" ];
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

    # Upstream deploys every localConfig file (scenarios, parsers, postoverflows, ...) as a tmpfiles
    # `L+` symlink named after its content-hashed store path, but never removes the previous
    # generation's link. Any change to e.g. the allowlist above therefore leaves two files declaring
    # the same `name` side by side, and crowdsec loads whichever sorts first ("multiple
    # postoverflows named ...: ignoring ..."), possibly the stale one. Prune any store-path symlink
    # under /etc/crowdsec that the current generation's tmpfiles rules no longer declare. Hub items
    # are symlinks into /var/lib/crowdsec, never /nix/store, so they're left alone.
    systemd.services.crowdsec-prune-stale-links = {
      description = "Remove CrowdSec local config symlinks left behind by previous generations";
      before = [ "crowdsec.service" ];
      requiredBy = [ "crowdsec.service" ];
      after = [ "systemd-tmpfiles-setup.service" "systemd-tmpfiles-resetup.service" ];
      serviceConfig.Type = "oneshot";
      script =
        let
          expected = lib.attrNames (lib.filterAttrs (_: v: v ? link)
            config.systemd.tmpfiles.settings."10-crowdsec");
        in
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

    # Upstream's crowdsec-update-hub.service (autoUpdateService above) always fails its
    # ExecStartPost, `systemctl reload crowdsec.service`, two ways at once: the sandboxed
    # DynamicUser it runs as is never D-Bus-authorized to reload units, and crowdsec.service has no
    # ExecReload= anyway (confirmed live - even plain root gets "Job type reload is not
    # applicable"). The `+` prefix runs just this command with full privileges to fix the first
    # issue; try-reload-or-restart (vs. reload) falls back to a full restart to fix the second.
    # Confirmed live via a `systemd-run` unit replicating the sandbox - crowdsec.service's
    # ActiveEnterTimestamp advanced when triggered this way.
    systemd.services.crowdsec-update-hub.serviceConfig.ExecStartPost =
      lib.mkForce "+systemctl try-reload-or-restart crowdsec.service";

    # Never serve the 0.0.0.0 LAPI without the firewall in place: if the ruleset fails to load at
    # boot, or nftables.service is stopped (which flushes it), crowdsec doesn't start or is stopped
    # with it. A switch only reloads nftables.service, which doesn't propagate, so firewall changes
    # don't restart crowdsec. systemd's IPAddressAllow/Deny can't do this job: it filters by
    # remote address in both directions, so it would also cut off the CAPI and hub.
    systemd.services.crowdsec.requires = [ "nftables.service" ];
    systemd.services.crowdsec.after = [ "nftables.service" ];

    systemd.services.crowdsec.serviceConfig = {
      # crowdsec-setup's ExecStartPre runs `cscli hub update`, which needs DNS. network-online only
      # means a link is routable, not that the resolver answers yet, so that lookup can still fail
      # ("Temporary failure in name resolution") and upstream sets RestartSec = 60 but no Restart=,
      # leaving the unit failed for good (hosts/vm-vps1 testing, 2026-10-07). Retry until DNS is up;
      # 60s spacing never trips the default start limit.
      Restart = "on-failure";
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/var/lib/crowdsec" "/etc/crowdsec" ];
      PrivateTmp = true;
      NoNewPrivileges = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
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

    systemd.services.crowdsec-firewall-bouncer.serviceConfig = {
      # The bouncer exits fatally ("bouncer stream halted") if crowdsec's LAPI isn't listening yet,
      # e.g. while crowdsec.service is still retrying its boot-time hub update above. Upstream sets
      # no Restart=, so keep retrying until the LAPI comes up.
      Restart = "on-failure";
      RestartSec = 30;

      # CAP_NET_ADMIN manipulates the nftables ruleset via netlink - cannot be capability-stripped
      # like the engine above. CAP_NET_RAW is NOT needed here: upstream's module only adds it for
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
  };
}
