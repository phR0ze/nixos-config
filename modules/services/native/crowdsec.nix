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

    whitelist = lib.mkOption {
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
  };

  config = lib.mkIf cfg.enable {
    secret.files."crowdsec/capiCredentials" = lib.mkIf (cfg.sopsFile != null) {
      sopsFile = cfg.sopsFile;
      user = config.services.crowdsec.user;
      group = config.services.crowdsec.group;
    };

    # crowdsec-firewall-bouncer manages its ruleset via nftables/netlink on this host (mode follows
    # `networking.nftables.enable`), which needs `nf_tables` loaded - and `devices.kernel.harden`'s
    # `security.lockKernelModules` (enabled alongside this module by `services.native.sshd.harden`)
    # blocks loading new modules after boot, so it must be preloaded here.
    boot.kernelModules = [ "nf_tables" ];

    services.crowdsec = {
      enable = true;
      settings.general.api.server.enable = true;   # local LAPI for the bouncer to query decisions from
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
        postOverflows.s01Whitelist = lib.optional (cfg.whitelist != [ ]) {
          name = "local/whitelist-management-ips";
          description = "Whitelist trusted management IPs from bans";
          whitelist = {
            reason = "trusted management IP";
            ip = cfg.whitelist;
          };
        };

        # Setting localConfig.profiles at all replaces the hub's profiles.yaml outright (it does
        # not merge). Upstream splits Ip/Range scope into two profiles since they can carry
        # different durations, but both use the same permanent duration here, so one profile
        # matching any actionable alert (Alert.Remediation == true) covers both.
        profiles = [
          {
            name = "permanent_ban";
            filters = [ "Alert.Remediation == true" ];
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
    };

    # Replaces upstream's broken crowdsec-firewall-bouncer-register.service (see comment above) -
    # same idempotent register-once-then-verify logic, just calling the working `cscli` wrapper
    # instead of the raw, unconfigured package binary.
    systemd.services.crowdsec-firewall-bouncer-register = {
      description = "Register the CrowdSec Firewall Bouncer to the local CrowdSec service";
      wantedBy = [ "multi-user.target" ];
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

    systemd.services.crowdsec.serviceConfig = {
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
