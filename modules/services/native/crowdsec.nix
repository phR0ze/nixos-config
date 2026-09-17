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

    capiCredentialsFile = lib.mkOption {
      description = ''
        Path to CrowdSec's Central API (CAPI) credentials file, enrolling this machine in
        CrowdSec's crowd-sourced blocklist (consuming other users' bans, not just your own local
        detections). Obtain it with a one-time `cscli capi register` run, then manage the
        resulting file via runtime secrets (sops-nix), never the Nix store. Leave null to only
        ban IPs this host has personally observed attacking it.
      '';
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
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

      # iptables adds port-scan detection against the dropped-connection logs enabled above - this
      # is what covers traffic that never touches any particular service's own logs at all.
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

      # registerBouncer.enable is broken upstream: crowdsec-firewall-bouncer-register.service
      # shells out to config.services.crowdsec.package's *raw* cscli binary with no `-c` flag, but
      # crowdsec.service itself only ever runs with `-c <store-path config.yaml>` - no config ever
      # lands at cscli's compiled-in default path (/etc/crowdsec/config.yaml), so every
      # registration attempt just errors "no configuration file found" (root cause is the same
      # class of bug as https://github.com/NixOS/nixpkgs/issues/459224 - a hardcoded-path
      # assumption in this module that doesn't match how crowdsec.service actually locates its
      # config - though that issue itself covers the separate capi-credentials grep bug, not this).
      # Register manually instead (below) using the fully wired-up `cscli` wrapper
      # services.crowdsec already exposes on PATH via environment.systemPackages - it already
      # carries the right `-c=<configFile>` and runs as the crowdsec user for us.
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
      # The `cscli` this script calls is upstream's own wrapper (services.crowdsec adds it to
      # environment.systemPackages, not to any package we can reference directly) - that only
      # lands on an interactive login shell's PATH, not a systemd unit's, so `path` needs
      # config.system.path (the merged systemPackages profile) to actually find it (confirmed via
      # a local quickemu VM test: failed "cscli: command not found" with only pkgs.jq here).
      path = [ pkgs.jq config.system.path ];
      script = ''
        set -euo pipefail
        apiKeyFile=/var/lib/crowdsec-firewall-bouncer-register/api-key.cred
        if cscli bouncers list --output json | jq -e 'any(.[]; .name == "crowdsec-firewall-bouncer")' >/dev/null; then
          if [ ! -f "$apiKeyFile" ]; then
            echo "Bouncer registered but API key is not present"
            exit 1
          fi
        else
          rm -f "$apiKeyFile"
          if ! cscli bouncers add --output raw -- crowdsec-firewall-bouncer >"$apiKeyFile"; then
            rm -f "$apiKeyFile"
            exit 1
          fi
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

    # Upstream's own crowdsec module creates every subdirectory it needs (state, hub, conf, ...)
    # via systemd.tmpfiles.settings "d" rules owned by cfg.user/cfg.group, but never creates
    # /var/lib/crowdsec itself that way - it relies on ReadWritePaths + DynamicUser's own
    # StateDirectory-less chown-on-start behavior for the root dir. Declaring
    # `StateDirectory = "crowdsec"` ourselves to plug that gap (a previous fix here) works on a
    # clean first boot, but combined with upstream's `PrivateUsers = true` it silently regresses on
    # the *next* boot: the two directory-ownership mechanisms disagree on which user-namespace view
    # the persisted DynamicUser uid mapping applies to, so /var/lib/crowdsec ends up owned by the
    # overflow uid (`nobody:nogroup`) instead of `crowdsec:crowdsec`, and crowdsec-setup's
    # `mkdir -p /var/lib/crowdsec/state/hub/` then fails with "Permission denied" (confirmed via a
    # local quickemu VM test: works on first activation, fails after a reboot). Matching upstream's
    # own tmpfiles-based approach for this one directory instead of StateDirectory sidesteps the
    # PrivateUsers/DynamicUser interaction entirely - the "state" subdirectory tmpfiles rule already
    # gets this right every boot, so extending the same mechanism to the parent does too.
    systemd.tmpfiles.settings."10-crowdsec-rootdir"."/var/lib/crowdsec".d = {
      user = config.services.crowdsec.user;
      group = config.services.crowdsec.group;
      mode = "0750";
    };

    # Upstream's own crowdsec-setup ExecStartPre guards `cscli machine add` with
    # `[ ! -s local_api_credentials.yaml ]` (skip if the file is already non-empty), but `cscli`
    # itself refuses to write to that path if it exists AT ALL, regardless of size - and separately,
    # refuses to (re-)register a machine name that's already in CrowdSec's local database, even if
    # its credentials file was lost. Either half of a registration can survive an interruption
    # without the other (e.g. a power loss right after the DB insert but before `cscli` finishes
    # writing the file, or right after the file is created but before it's populated - both
    # confirmed via a local quickemu VM test simulating this), leaving `crowdsec.service` failing
    # permanently on every subsequent start with either "file already exists" or "user already
    # exist" until someone manually intervenes.
    #
    # This can't be plugged in via `serviceConfig.ExecStartPre` from our own module (tried
    # `lib.mkBefore` first): upstream's own ExecStartPre list opens with a literal blank entry
    # (`" " # This is needed to clear the ExecStartPre definitions from upstream`), which is
    # systemd's own "wipe everything declared before this line in the unit file" directive. That
    # blank entry always renders *after* anything a separate module contributes regardless of
    # mkBefore/mkAfter priority, so it silently erased our step before it ever ran (confirmed via
    # a local quickemu VM test: `systemctl cat` showed our ExecStartPre line present in the unit
    # file, but it never actually executed). `mkAfter` doesn't work either - crowdsec-setup's own
    # failure aborts the unit before a later ExecStartPre step would get a chance to run. A fully
    # separate unit, ordered via normal `before`/`requiredBy`, sidesteps upstream's internal list
    # entirely.
    #
    # Rather than just deleting a stale file and hoping upstream's own retry succeeds (it won't, if
    # the DB-side registration also survived), proactively (re-)complete the registration ourselves
    # with `--force` whenever the file isn't already valid - `--force` covers both "file exists" and
    # "machine already exists" in one shot, per `cscli machines add --help`. Once this produces a
    # valid, non-empty file, upstream's own `[ ! -s ... ]` guard just skips its attempt as normal.
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
      # Needs CAP_NET_ADMIN/CAP_NET_RAW to manipulate iptables - cannot be capability-stripped like
      # the engine above.
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
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
    };
  };
}
