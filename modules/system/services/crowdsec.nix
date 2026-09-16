# CrowdSec configuration
#
# ### Purpose
# - Generic detection engine + firewall bouncer wiring, shared by any service that wants to feed it
#   acquisitions/scenarios/collections (e.g. system.services.sshd contributes SSH-specific detection
#   on top of this when its own harden option is enabled)
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  cfg = config.system.services.crowdsec;
in
{
  options.system.services.crowdsec = {
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
  };
}
