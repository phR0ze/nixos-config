# Alerting - via ntfy topics about various host concerns
#
# ### Features
# - Configurable alerts for failed systemd units
# - Configurable alerts for CrowdSec activity
# - Configurable alerts for missing, failed or stale `backup-<name>` units
# - Configurable alerts for down/unhealthy podman containers
# - Configurable alerts for new upstream releases of pinned container images
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

  podman = "${config.virtualisation.podman.package}/bin/podman";

  # Split each registered tag into the image-only prefix upstream release names don't carry (`v`,
  # or `ee-` for Pangolin's Enterprise images) and the version proper. A floating tag with no
  # version (`latest`, `lts`) can't be compared against a release, so it's dropped here. A
  # major.minor-only tag (traefik `v3.7`) is republished upstream on every patch, so it's compared
  # at major.minor only - only a new minor/major series is news.
  versionedImages = lib.filterAttrs (_: img: img != null) (lib.mapAttrs (_: img:
    let m = builtins.match "([^0-9]*)([0-9]+(\\.[0-9]+)*)" img.tag; in
    if m == null then null else {
      inherit (img) tag repo;
      prefix = lib.elemAt m 0;
      version = lib.elemAt m 1;
      minorOnly = builtins.length (lib.splitString "." (lib.elemAt m 1)) == 2;
    }) cfg.imageUpdates.images);
in
{
  options.services.native.alerts = {
    enable = lib.mkEnableOption "push notifications for failed units, plus whatever backups, containers and images services register";

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
        default = false;
      };

      crowdsecContainers = lib.mkOption {
        description = ''
          Podman containers running their own CrowdSec engine (separate from the host's, with its
          own decisions), whose active decision count is reported alongside the host's. Each
          module running one adds its own entry, rather than this being listed per host.
        '';
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "crowdsec" ];
      };

      time = lib.mkOption {
        description = "When the digest is pushed, as a systemd `OnCalendar` expression";
        type = lib.types.str;
        default = "05:00";
        example = "Mon 08:00";
      };
    };

    backup = {
      services = lib.mkOption {
        description = ''
          Names of the services whose `backup-<name>.service` units are checked, pushing a
          notification when the set of unhealthy backups changes - a unit that's missing, whose
          last run failed, or that hasn't succeeded in the last 26h (a nightly schedule plus
          slack). Each service that supports backups adds its own name here when its `backupDir`
          is set, rather than this being listed per host. Empty (the default) disables the check.
        '';
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "jellyfin" "vaultwarden" ];
      };

      interval = lib.mkOption {
        description = ''
          How often to check the backups, as a systemd time span (`OnUnitActiveSec`). Also the
          worst-case delay between a backup failing and the notification going out.
        '';
        type = lib.types.str;
        default = "1h";
        example = "15min";
      };
    };

    containers = {
      units = lib.mkOption {
        description = ''
          Podman containers to watch, keyed by the systemd unit that owns them (without
          `.service`), pushing a notification when the set of down or unhealthy containers
          changes. A container stack started by a oneshot unit (e.g. podman-compose `up -d`) keeps
          that unit `active` even once a container crash-loops or exits, so the failed-unit check
          never sees it. Containers are only checked while their unit is `active`: a stopped,
          restarting or failed unit is either intentional or already reported by `failedUnits`.
          Separately, any unit systemd has auto-restarted since the last check is reported too,
          whatever its state - this is what catches a container crash-looping too slowly to hit
          the unit's start limit (and so never showing up as failed).
          Each module running containers adds its own entry, rather than this being listed per
          host. Empty disables the check.
        '';
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = { };
        example = { pangolin-stack = [ "pangolin" "gerbil" "traefik" "crowdsec" ]; };
      };

      ociContainers = lib.mkOption {
        description = ''
          Watch every `virtualisation.oci-containers` container (each run by its own
          `<backend>-<name>` unit) without each module registering it in `units` itself.
        '';
        type = lib.types.bool;
        default = true;
      };

      interval = lib.mkOption {
        description = ''
          How often to check the containers, as a systemd time span (`OnUnitActiveSec`). Also the
          worst-case delay between a container going down and the notification going out.
        '';
        type = lib.types.str;
        default = "5min";
        example = "1min";
      };
    };

    imageUpdates = {
      images = lib.mkOption {
        description = ''
          Pinned container images to compare against their upstream project's latest GitHub
          release, pushing a notification when the set of outdated images changes. A notice only,
          never an update - bumping a pin stays a deliberate change after reading the release
          notes. Each module running pinned images adds its own entries, rather than this being
          listed per host. A tag's non-numeric prefix (`v`, `ee-`) is kept on the reported version
          and a major.minor tag (`v3.7`) is compared at major.minor only; a tag with no version in
          it (`latest`, `lts`) is skipped. Empty disables the check.
        '';
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            tag = lib.mkOption {
              description = "The image tag currently pinned";
              type = lib.types.str;
              example = "v1.7.8";
            };
            repo = lib.mkOption {
              description = "GitHub `owner/repo` whose latest release is compared against `tag`";
              type = lib.types.str;
              example = "crowdsecurity/crowdsec";
            };
          };
        });
        default = { };
        example = { crowdsec = { tag = "v1.7.8"; repo = "crowdsecurity/crowdsec"; }; };
      };

      time = lib.mkOption {
        description = "When to check for new releases, as a systemd `OnCalendar` expression";
        type = lib.types.str;
        default = "09:00";
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
        # The `cscli` wrapper only lands on environment.systemPackages, so config.system.path is
        # needed for the unit to find it - see crowdsec-firewall-bouncer-register in crowdsec.nix
        path = lib.optional config.services.native.crowdsec.enable config.system.path;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = toString (pkgs.writeShellScript "security-digest" (''
            set -uo pipefail
            ${ntfyFunc}
            HOST=${config.networking.hostName}

            # Rejected SSH logins, one line per connection that never authenticated. Matching on
            # these rather than "Failed password" works with key-only auth (sshd.harden), and avoids
            # counting a legit client's agent trying a wrong key before the right one. openssh 9.8+
            # logs auth from sshd-session (10.x also sshd-auth) rather than sshd, and socket
            # activation renames the unit, so match the syslog identifiers instead of `-u sshd`.
            # Counts only - never the matched lines, which carry source IPs and usernames.
            SSH_REJECTS=$(journalctl -t sshd -t sshd-session -t sshd-auth --since "-1 day" -o cat \
              | grep -E 'Invalid user |Connection closed by authenticating user |Disconnecting authenticating user ' \
              || true)
            SSH_COUNT=$(printf '%s' "$SSH_REJECTS" | grep -c . || true)
            SSH_SOURCES=$(printf '%s' "$SSH_REJECTS" | grep -oE '[^ ]+ port [0-9]+' | cut -d' ' -f1 \
              | sort -u | grep -c . || true)
            MSG="Rejected SSH logins (last 24h): $SSH_COUNT from $SSH_SOURCES source(s)"
          ''
          # Only report CrowdSec on hosts running it, and say so if cscli fails rather than
          # reporting a misleading 0
          + lib.optionalString config.services.native.crowdsec.enable ''
            if CS_RAW=$(cscli decisions list -o raw 2>/dev/null); then
              CS_DECISIONS=$(printf '%s\n' "$CS_RAW" | tail -n +2 | grep -c . || true)
            else
              CS_DECISIONS="unavailable (cscli failed)"
            fi
            MSG="$MSG"$'\n'"Active CrowdSec decisions (host): $CS_DECISIONS"
          ''
          # Each containerized engine is a separate LAPI with its own decisions, never visible to
          # the host's cscli
          + lib.concatMapStrings (c: ''
            if CS_RAW=$(${podman} exec ${lib.escapeShellArg c} cscli decisions list -o raw 2>/dev/null); then
              CS_DECISIONS=$(printf '%s\n' "$CS_RAW" | tail -n +2 | grep -c . || true)
            else
              CS_DECISIONS="unavailable (cscli failed)"
            fi
            MSG="$MSG"$'\n'"Active CrowdSec decisions (container ${c}): $CS_DECISIONS"
          '') cfg.securityDigest.crowdsecContainers
          + ''
            ntfy -H "Title: [ $HOST ] Daily security digest" -d "$MSG"
          ''));
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

    (lib.mkIf (cfg.backup.services != [ ]) {
      systemd.services.check-backups = {
        description = "Push a notification when the set of unhealthy backups changes";
        serviceConfig = {
          Type = "oneshot";
          StateDirectory = "alerts";
          ExecStart = toString (pkgs.writeShellScript "check-backups" ''
            set -uo pipefail
            ${ntfyFunc}
            HOST=${config.networking.hostName}
            STATE_DIR=/var/lib/alerts
            STATE_FILE=$STATE_DIR/backups.state
            MAX_AGE=$((26 * 3600))
            NOW=$(date +%s)

            # systemd forgets a unit's last run on reboot, so each backup's last successful finish
            # is persisted here instead. A service with no record yet is seeded with now, giving
            # it MAX_AGE to produce its first success rather than alerting straight after deploy.
            PROBLEMS=""
            for svc in ${lib.escapeShellArgs cfg.backup.services}; do
              unit="backup-$svc.service"
              last_file="$STATE_DIR/backup-$svc.last"
              [ -s "$last_file" ] || echo "$NOW" > "$last_file"

              if [ "$(systemctl show -P LoadState "$unit")" != "loaded" ]; then
                PROBLEMS+="$svc: backup unit not found"$'\n'
                continue
              fi

              # Result stays `success` for a unit that hasn't run this boot, so only an exit
              # timestamp means there's a real run to record
              result=$(systemctl show -P Result "$unit")
              exited=$(systemctl show --timestamp=unix -P ExecMainExitTimestamp "$unit")
              exited=''${exited#@}
              if [ "$result" != "success" ]; then
                PROBLEMS+="$svc: last backup run failed ($result)"$'\n'
              elif [ -n "$exited" ] && [ "$exited" -gt "$(cat "$last_file")" ]; then
                echo "$exited" > "$last_file"
              fi

              # No age in the message, otherwise it changes every check and re-notifies
              if [ $((NOW - $(cat "$last_file"))) -gt "$MAX_AGE" ]; then
                PROBLEMS+="$svc: no successful backup in over 26h"$'\n'
              fi
            done
            # Drop the trailing newline so it compares equal to PREV, which $(cat) strips too
            PROBLEMS=$(printf '%s' "$PROBLEMS")

            PREV=$(cat "$STATE_FILE" 2>/dev/null || true)
            if [ "$PROBLEMS" != "$PREV" ]; then
              if [ -n "$PROBLEMS" ]; then
                ntfy -H "Title: [ $HOST ] backup problem" -H "Priority: high" -d "$PROBLEMS"
              else
                ntfy -H "Title: [ $HOST ] backups recovered" \
                  -d "All previously unhealthy backups are healthy again"
              fi
            fi
            printf '%s' "$PROBLEMS" > "$STATE_FILE"
          '');
        };
      };

      systemd.timers.check-backups = {
        description = "Check backup health every ${cfg.backup.interval}";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = cfg.backup.interval;
        };
      };
    })

    (lib.mkIf cfg.containers.ociContainers {
      services.native.alerts.containers.units = lib.mapAttrs'
        (name: _: lib.nameValuePair "${config.virtualisation.oci-containers.backend}-${name}" [ name ])
        config.virtualisation.oci-containers.containers;
    })

    (lib.mkIf (cfg.containers.units != { }) {
      systemd.services.check-containers = {
        description = "Push a notification when the set of down or unhealthy containers changes";
        serviceConfig = {
          Type = "oneshot";
          StateDirectory = "alerts";
          ExecStart = toString (pkgs.writeShellScript "check-containers" (''
            set -uo pipefail
            ${ntfyFunc}
            HOST=${config.networking.hostName}
            STATE_FILE=/var/lib/alerts/containers.state

            # One snapshot for every check. `.Status` is free-form ("Up 3 hours (unhealthy)"), so
            # only its health suffix is used - never the uptime, which changes every run and would
            # re-notify
            PS=$(${podman} ps -a --format '{{.Names}}|{{.State}}|{{.Status}}')
            PROBLEMS=""
          '' + lib.concatStrings (lib.mapAttrsToList (unit: names: ''
            # NRestarts only counts systemd's own automatic restarts (a container that exited
            # under Restart=), and resets on a manual start - so any increase since the last check
            # means it died on its own. Reported regardless of the unit's state, since a crash loop
            # spends most of its time `activating`/`auto-restart` rather than `active`.
            restarts=$(systemctl show -P NRestarts ${lib.escapeShellArg "${unit}.service"})
            last_file=${lib.escapeShellArg "/var/lib/alerts/restarts-${unit}"}
            last=$(cat "$last_file" 2>/dev/null || echo "$restarts")
            if [ "''${restarts:-0}" -gt "''${last:-0}" ]; then
              PROBLEMS+=${lib.escapeShellArg "${unit}: restarted by systemd after exiting"}$'\n'
            fi
            echo "''${restarts:-0}" > "$last_file"

            if [ "$(systemctl show -P ActiveState ${lib.escapeShellArg "${unit}.service"})" = "active" ]; then
              for c in ${lib.escapeShellArgs names}; do
                line=$(printf '%s\n' "$PS" | grep -m1 "^$c|" || true)
                state=$(printf '%s' "$line" | cut -d'|' -f2)
                if [ -z "$line" ]; then
                  PROBLEMS+="$c: missing"$'\n'
                elif [ "$state" != "running" ]; then
                  PROBLEMS+="$c: $state"$'\n'
                elif [[ "$line" == *"(unhealthy)"* ]]; then
                  PROBLEMS+="$c: unhealthy"$'\n'
                fi
              done
            fi
          '') cfg.containers.units) + ''
            # Drop the trailing newline so it compares equal to PREV, which $(cat) strips too
            PROBLEMS=$(printf '%s' "$PROBLEMS")

            PREV=$(cat "$STATE_FILE" 2>/dev/null || true)
            if [ "$PROBLEMS" != "$PREV" ]; then
              if [ -n "$PROBLEMS" ]; then
                ntfy -H "Title: [ $HOST ] container down" -H "Priority: high" -d "$PROBLEMS"
              else
                ntfy -H "Title: [ $HOST ] containers recovered" \
                  -d "All previously down, unhealthy or restarting containers are running again"
              fi
            fi
            printf '%s' "$PROBLEMS" > "$STATE_FILE"
          ''));
        };
      };

      systemd.timers.check-containers = {
        description = "Check container health every ${cfg.containers.interval}";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = cfg.containers.interval;
        };
      };
    })

    (lib.mkIf (versionedImages != { }) {
      systemd.services.check-image-updates = {
        description = "Push a notification when pinned container images fall behind upstream";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          StateDirectory = "alerts";
          ExecStart = toString (pkgs.writeShellScript "check-image-updates" (''
            set -uo pipefail
            ${ntfyFunc}
            HOST=${config.networking.hostName}
            STATE_FILE=/var/lib/alerts/image-updates.state
            PREV=$(cat "$STATE_FILE" 2>/dev/null || true)
            REPORT=""

            # Latest non-prerelease release tag, with any leading `v` dropped so `v1.7.8` and
            # `1.7.8` compare equal
            latest() {
              ${pkgs.curl}/bin/curl -sf --max-time 30 \
                "https://api.github.com/repos/$1/releases/latest" \
                | ${pkgs.jq}/bin/jq -er '.tag_name' | sed 's/^v//'
            }
          '' + lib.concatStrings (lib.mapAttrsToList (name: img: ''
            if new=$(latest ${lib.escapeShellArg img.repo}); then
              ${lib.optionalString img.minorOnly ''new=$(printf '%s' "$new" | cut -d. -f1-2)''}
              if [ "$new" != ${lib.escapeShellArg img.version} ]; then
                REPORT+=${lib.escapeShellArg "${name}: ${img.tag} -> ${img.prefix}"}"$new"$'\n'
              fi
            else
              # Keep the last known result rather than flip-flopping the state on a failed fetch
              old=$(printf '%s\n' "$PREV" | grep -m1 ${lib.escapeShellArg "^${name}: "} || true)
              [ -n "$old" ] && REPORT+="$old"$'\n'
            fi
          '') versionedImages) + ''
            # Drop the trailing newline so it compares equal to PREV, which $(cat) strips too
            REPORT=$(printf '%s' "$REPORT")

            # Report only newly changed results - a still-outdated pin doesn't re-notify daily,
            # and catching up on a pin is its own confirmation
            if [ "$REPORT" != "$PREV" ] && [ -n "$REPORT" ]; then
              ntfy -H "Title: [ $HOST ] new container image version(s)" -d "$REPORT"
            fi
            printf '%s' "$REPORT" > "$STATE_FILE"
          ''));
        };
      };

      systemd.timers.check-image-updates = {
        description = "Check pinned container images for new upstream releases";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.imageUpdates.time;
          Persistent = true;
          RandomizedDelaySec = "15min";
        };
      };
    })
  ]);
}
