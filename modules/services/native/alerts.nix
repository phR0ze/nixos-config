# Alerting - failed-unit push notifications + a daily security digest
#
# ### Purpose
# - Pushes an ntfy.sh notification the moment any systemd unit enters (or recovers from) a failed
#   state, and a daily digest summarizing sshd/CrowdSec activity - so an incident like
#   crowdsec-update-hub.service's silently-failing ExecStartPost (see modules/services/native/crowdsec.nix)
#   surfaces on its own instead of waiting for someone to happen to check.
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.services.native.alerts;
  ntfyTopicFile = config.secret.files."alerts/ntfyTopic".path;
in
{
  options.services.native.alerts = {
    enable = lib.mkEnableOption "push notifications for failed systemd units and a daily security digest";

    sopsFile = lib.mkOption {
      description = ''
        Path to the host's `secrets.enc.yaml`, decrypted at activation time by sops-nix to source
        the ntfy.sh topic both the failed-unit alert and the daily digest push to. The topic is a
        runtime-only value (read by a shell script, not consumed by any NixOS module option at
        evaluation time) so it lives here rather than in `args.enc.yaml` - see this repo's
        `CLAUDE.md` §7 on build-time args vs. runtime secrets.
      '';
      type = lib.types.nullOr lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = cfg.sopsFile != null;
        message = "services.native.alerts.enable requires services.native.alerts.sopsFile (host.secrets) to be set"; }
    ];

    secret.files."alerts/ntfyTopic".sopsFile = cfg.sopsFile;

    systemd.services.check-failed-units = {
      description = "Push a notification when the set of failed systemd units changes";
      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "alerts";
        ExecStart = toString (pkgs.writeShellScript "check-failed-units" ''
          set -uo pipefail
          STATE_FILE=/var/lib/alerts/failed-units.state
          TOPIC=$(cat ${ntfyTopicFile})
          HOST=$(hostname)
          FAILED=$(systemctl --failed --no-legend --plain)
          PREV=$(cat "$STATE_FILE" 2>/dev/null || true)
          if [ "$FAILED" != "$PREV" ]; then
            if [ -n "$FAILED" ]; then
              ${pkgs.curl}/bin/curl -sf -H "Title: systemd unit failure on $HOST" -H "Priority: high" \
                -d "[$HOST]
$FAILED" "https://ntfy.sh/$TOPIC"
            else
              ${pkgs.curl}/bin/curl -sf -H "Title: systemd units recovered on $HOST" \
                -d "[$HOST] All previously failed units are healthy again" "https://ntfy.sh/$TOPIC"
            fi
          fi
          echo "$FAILED" > "$STATE_FILE"
        '');
      };
    };

    systemd.timers.check-failed-units = {
      description = "Check for failed systemd units every 5 minutes";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "5min";
      };
    };

    systemd.services.security-digest = {
      description = "Push a daily summary of sshd/CrowdSec activity";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = toString (pkgs.writeShellScript "security-digest" ''
          set -uo pipefail
          TOPIC=$(cat ${ntfyTopicFile})
          HOST=$(hostname)
          AUTH_FAILS=$(journalctl -u sshd --since "-1 day" | grep -c "Failed password" || true)
          CS_DECISIONS=$(cscli decisions list -o raw 2>/dev/null | tail -n +2 | wc -l || echo 0)
          ${pkgs.curl}/bin/curl -sf -H "Title: Daily security digest - $HOST" -d "$(cat <<MSG
          [$HOST]
          Failed SSH password attempts (last 24h): $AUTH_FAILS
          Active CrowdSec decisions: $CS_DECISIONS
          MSG
          )" "https://ntfy.sh/$TOPIC"
        '');
      };
    };

    systemd.timers.security-digest = {
      description = "Push the daily security digest";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "05:00";
        Persistent = true;
      };
    };
  };
}
