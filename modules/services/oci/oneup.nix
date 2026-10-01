# OneUp configuration
# - https://github.com/phR0ze/oneup
#
# ### Description
# Flutter application for tracking points
#
# ### Deployment Features
# - Get status with: `systemctl status podman-oneup`
#
# ### Backup process
# - `<backupDir>/oneup` gets a nightly snapshot at `backupTime` of `/var/lib/oneup/data`: the container is
#   stopped, the data dir rsynced over, then the container restarted. Each run overwrites the last
# - Stopping is the simplest way to get a consistent copy of the app's database
#
# **Trigger backup**
# sudo systemctl start backup-oneup
# 
# ### Manual Backup
# 1. Stop the service
#    sudo systemctl stop podman-oneup
#
# 2. Run the backup
#    sudo rsync -a --delete /var/lib/oneup/data/ /mnt/Apps/homelab/oneup/
#
# 3. Start the service backup
#    sudo systemctl start podman-oneup
#
# #### Restore
# The backup share doesn't preserve ownership or modes (everything comes back with the mount's
# forced owner and modes), so the restore copies content only (`-rlt`, leaving the live dirs'
# modes alone) and then resets ownership recursively.
#
# 1. Stop the service
#    sudo systemctl stop podman-oneup
#
# 2. Restore the data
#    sudo rsync -rlt --delete <backupDir>/oneup/ /var/lib/oneup/data/
#
# 3. Reset ownership to the app user the container runs as (`user.uid`/`user.gid`)
#    sudo chown -R oneup:oneup /var/lib/oneup/data
#
# 4. Start the service
#    sudo systemctl start podman-oneup
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.services.oci.oneup;
in
{
  options.services.oci.oneup = (import ../../types/service.nix {
    inherit lib;
    defaults = {
      name = "oneup";
      caddy = true;
      subdomain = "oneup";
      capDropAll = true;
      noNewPrivileges = true;
      readOnlyRootfs = true;
    };
  }) // {
    backupDir = lib.mkOption {
      description = ''
        Parent directory to snapshot `/var/lib/<name>/data` into nightly, as `<backupDir>/<name>`,
        overwriting the previous run - see the backup process notes above. Forwarded from
        `host.backupDir` by `modules/default.nix`. Must be outside `/var/lib/<name>`. `null`
        disables backups.
      '';
      type = types.nullOr types.str;
      default = null;
      example = "/mnt/Apps/homelab";
    };

    backupTime = lib.mkOption {
      description = ''
        When the nightly `backupDir` snapshot runs, as a systemd `OnCalendar` expression. The
        container is stopped for the duration of the run.
      '';
      type = types.str;
      default = "00:00";
      example = "Sun 02:30";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = f.ociAsserts cfg ++ [
        { assertion = cfg.caddy -> cfg.subdomain != null;
          message = "services.oci.oneup: 'caddy' requires 'subdomain' to be set";
        }
      ];

      virtualization.podman.enable = true;
      users.users.${cfg.user.name} = f.createUser cfg.user;
      users.groups.${cfg.user.group} = f.createGroup cfg.user;

      # Create persistent directories for application
      # - Args: type, path, mode, user, group, expiration
      # - No group specified, i.e `-` defaults to root
      # - No age specified, i.e `-` defaults to infinite
      systemd.tmpfiles.rules = [
        "d /var/lib/${cfg.name}/data 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      ];

      # Generate the "podman-${cfg.name}" service unit for the container
      virtualisation.oci-containers.containers."${cfg.name}" = {
        hostname = "${cfg.name}";
        user = "${toString cfg.user.uid}:${toString cfg.user.gid}";
        image = "ghcr.io/phr0ze/${cfg.name}:${cfg.tag}";
        autoStart = true;
        networks = [ cfg.name ];                  # Isolated app specific network
        # Loopback-only when fronted by Caddy, otherwise published on the LAN
        ports = [ "${lib.optionalString cfg.caddy "127.0.0.1:"}${toString cfg.port}:8080" ];
        volumes = [ "/var/lib/${cfg.name}/data:/app/data:rw" ];
        environment = { "PORT" = "8080"; };
        extraOptions = [ "--ip=${cfg.ip}" ]
          ++ lib.optionals cfg.capDropAll [ "--cap-drop=ALL" ]
          ++ lib.optionals cfg.noNewPrivileges [ "--security-opt=no-new-privileges" ]
          ++ lib.optionals cfg.readOnlyRootfs [ "--read-only" "--tmpfs=/tmp" ];
      };

      # Create podmane network and extend service to use it
      systemd.services."podman-network-${cfg.name}" = f.createContNetwork { name = cfg.name; subnet = cfg.subnet; };
      systemd.services."podman-${cfg.name}" = f.extendContService { name = cfg.name; };

      networking.firewall.allowedTCPPorts = lib.optional (!cfg.caddy) cfg.port;
    }

    # Nightly stop -> rsync -> start snapshot of the data dir
    # - Runs as root since it has to stop/start the service; rsync -a keeps the app user's ownership
    # - The EXIT trap restarts the container even if rsync fails, but only if it was running beforehand
    # - No wantedBy on the service itself so it never fires (and takes oneup down) at boot
    (lib.mkIf (cfg.backupDir != null) (let
      dataDir = "/var/lib/${cfg.name}";
      unit = "podman-${cfg.name}.service";
      backupDir = "${cfg.backupDir}/${cfg.name}";
    in {
      assertions = [
        { assertion = !(lib.hasPrefix "${dataDir}/" "${backupDir}/");
          message = "services.oci.oneup.backupDir must be outside ${dataDir}"; }
      ];

      # Have services.native.alerts watch this backup
      services.native.alerts.enable = lib.mkDefault true;
      services.native.alerts.backup.services = [ cfg.name ];

      systemd.tmpfiles.rules = [
        "d ${backupDir} 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      ];

      systemd.services."backup-${cfg.name}" = {
        description = "Backup OneUp data dir";
        path = [ pkgs.rsync config.systemd.package ];
        serviceConfig.Type = "oneshot";
        script = ''
          set -euo pipefail
          if systemctl is-active --quiet ${unit}; then
            trap 'systemctl start ${unit}' EXIT
            systemctl stop ${unit}
          fi
          rsync -a --delete ${dataDir}/data/ ${backupDir}/
        '';
      };

      systemd.timers."backup-${cfg.name}" = {
        description = "Backup OneUp nightly";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.backupTime;
          Persistent = true;
        };
      };
    }))

    # Contribute a proxy entry to services.native.caddy.proxies rather than requiring it be listed
    # separately in the machine's configuration.nix
    (lib.mkIf cfg.caddy {
      services.native.caddy.enable = lib.mkDefault true;
      services.native.caddy.proxies = [
        { inherit (cfg) subdomain port; }
      ];
    })
  ]);
}
