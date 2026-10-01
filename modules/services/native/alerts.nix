# Alerting - via ntfy topics about various host concerns
#
# ### Features
# - Configurable alerts for failed systemd units
# - Configurable alerts for CrowdSec activity
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.services.native.alerts;
  ntfyTopicFile = config.secret.files.${cfg.ntfyTopicSecretRef}.path;

  # Shell function both scripts push through. The topic is the only thing gating who can read the
  # notifications, so the URL is fed to curl as a config on stdin (`-K -`) rather than as an
  # argument - argv is world-readable via `ps`/`/proc/<pid>/cmdline` for as long as curl runs.
  # `printf` is a bash builtin so it never exposes the topic in argv either.
  ntfyFunc = ''
    ntfy() {
      printf 'url = "https://ntfy.sh/%s"\n' "$(cat ${ntfyTopicFile})" \
        | ${pkgs.curl}/bin/curl -sf -K - "$@"
    }
  '';
in
{
  options.services.native.alerts = {
    enable = lib.mkEnableOption "push notifications for failed systemd units and a daily security digest";

    sopsFile = lib.mkOption {
      description = ''
        Path to the host's `secrets.enc.yaml`, decrypted at activation time by sops-nix to source
        the ntfy.sh topic that all the alerts share as their output path.
      '';
      type = lib.types.nullOr lib.types.path;
    };

    ntfyTopicSecretRef = lib.mkOption {
      description = ''
        Key path within `sopsFile` holding the ntfy.sh topic both the failed-unit alert and the
        daily digest push to.
      '';
      type = lib.types.str;
      default = "alerts/ntfyTopic";
    };

    failedUnits = {
      enable = lib.mkOption {
        description = "Push a notification when the set of failed systemd units changes";
        type = lib.types.bool;
        default = true;
      };

      interval = lib.mkOption {
        description = ''
          How often to poll for failed units, as a systemd time span (`OnUnitActiveSec`). Also the
          worst-case delay between a unit failing and the notification going out.
        '';
        type = lib.types.str;
        default = "5min";
        example = "1min";
      };
    };

    securityDigest = {
      enable = lib.mkOption {
        description = "Push a daily summary of sshd/CrowdSec activity";
        type = lib.types.bool;
        default = true;
      };

      time = lib.mkOption {
        description = "When the digest is pushed, as a systemd `OnCalendar` expression";
        type = lib.types.str;
        default = "05:00";
        example = "Mon 08:00";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        { assertion = cfg.sopsFile != null;
          message = "services.native.alerts.enable requires services.native.alerts.sopsFile (host.secrets) to be set"; }
      ];

      secret.files.${cfg.ntfyTopicSecretRef}.sopsFile = cfg.sopsFile;
    }

    (lib.mkIf cfg.failedUnits.enable {
      systemd.services.check-failed-units = {
        description = "Push a notification when the set of failed systemd units changes";
        serviceConfig = {
          Type = "oneshot";
          StateDirectory = "alerts";
          ExecStart = toString (pkgs.writeShellScript "check-failed-units" ''
            set -uo pipefail
            STATE_FILE=/var/lib/alerts/failed-units.state
            ${ntfyFunc}
            HOST=${config.networking.hostName}
            # Unit names and sub-state only. The free-form description is dropped
            FAILED=$(systemctl --failed --no-legend --plain | while read -r unit _load _active sub _; do
              echo "$unit ($sub)"
            done)
            PREV=$(cat "$STATE_FILE" 2>/dev/null || true)
            if [ "$FAILED" != "$PREV" ]; then
              if [ -n "$FAILED" ]; then
                ntfy -H "Title: [ $HOST ] systemd unit failure" -H "Priority: high" -d "$FAILED"
              else
                ntfy -H "Title: [ $HOST ] systemd units recovered" \
                  -d "All previously failed units are healthy again"
              fi
            fi
            echo "$FAILED" > "$STATE_FILE"
          '');
        };
      };

      systemd.timers.check-failed-units = {
        description = "Check for failed systemd units every ${cfg.failedUnits.interval}";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2min";
          OnUnitActiveSec = cfg.failedUnits.interval;
        };
      };
    })

    (lib.mkIf cfg.securityDigest.enable {
      systemd.services.security-digest = {
        description = "Push a daily summary of sshd/CrowdSec activity";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = toString (pkgs.writeShellScript "security-digest" ''
            set -uo pipefail
            ${ntfyFunc}
            HOST=${config.networking.hostName}
            # Counts only - never the matched log lines, which carry source IPs and usernames
            AUTH_FAILS=$(journalctl -u sshd --since "-1 day" | grep -c "Failed password" || true)
            CS_DECISIONS=$(cscli decisions list -o raw 2>/dev/null | tail -n +2 | wc -l || echo 0)
            ntfy -H "Title: [ $HOST ] Daily security digest" -d "$(cat <<MSG
            Failed SSH password attempts (last 24h): $AUTH_FAILS
            Active CrowdSec decisions: $CS_DECISIONS
            MSG
            )"
          '');
        };
      };

      systemd.timers.security-digest = {
        description = "Push the daily security digest";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.securityDigest.time;
          Persistent = true;
        };
      };
    })
  ]);
}
