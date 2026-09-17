# CrowdSec configuration
#
# ### Purpose
# - Generic detection engine + firewall bouncer wiring, shared by any service that wants to feed it
#   acquisitions/scenarios/collections (e.g. services.native.sshd contributes SSH-specific detection
#   on top of this when its own harden option is enabled)
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
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

    services.crowdsec-firewall-bouncer.enable = true;   # applies CrowdSec's ban decisions via iptables

    systemd.services.crowdsec.serviceConfig = {
      # Upstream's own crowdsec module uses DynamicUser without declaring StateDirectory, so
      # systemd never reliably owns/persists /var/lib/crowdsec (a `-> private/crowdsec` symlink)
      # across restarts - its ExecStartPre `mkdir /var/lib/crowdsec` then fails with "Permission
      # denied", reproducibly even on a clean boot. Declaring it here makes systemd create/chown
      # that directory and consistently reuse the same DynamicUser uid for it, as intended.
      StateDirectory = "crowdsec";
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
