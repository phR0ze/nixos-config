# Jellyfin
#
# ### Description
# Jellyfin is a Free Software Media System that puts you in control of managing and streaming your 
# media. It's an alternative to the proprietary Emby and Plex.
#
# - Cross-platform client support: MacOS, Windows, Linux and Android
# - Remote control of Kodi or Jellyfin Media Player or Jellyfin MPV Shim via mobile app
#
# ### Backup process
# - `<backupDir>/jellyfin` gets a nightly snapshot at `backupTime` from `/var/lib/jellyfin` minus its logs
#   the service is stopped, the data dir rsynced over, then the service restarted.
# - Jellyfin's SQLite DB runs in WAL mode and `metadata/` is written alongside it, so stopping is the
#   simplest way to get a consistent copy. Each run overwrites the last
# - `/var/cache/jellyfin` (transcodes, resized images, extracted subtitles) is regenerable and skipped.
#
# **Trigger backup**
# sudo systemctl start backup-jellyfin
#
# #### Restore
# The backup share doesn't preserve ownership or modes (everything comes back with the mount's
# forced owner and modes), so the restore copies content only (`-rlt`, leaving the live dirs'
# modes alone) and then resets ownership recursively.
#
# 1. Stop the service
#    sudo systemctl stop jellyfin
#
# 2. Restore the data
#    sudo rsync -rlt --delete <backupDir>/jellyfin/ /var/lib/jellyfin/
#
# 3. Reset ownership
#    sudo chown -R jellyfin:jellyfin /var/lib/jellyfin
#
# 4. Start the service
#    sudo systemctl start jellyfin
#
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.services.native.jellyfin;
in
{
  options = {
    services.native.jellyfin = {
      enable = lib.mkEnableOption "Install and configure Jellyfin server";

      port = lib.mkOption {
        type = lib.types.port;
        default = 8096;
        description = "Port the Jellyfin web/API server listens on.";
      };

      caddy = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Front Jellyfin with `services.native.caddy` (enabled by default along with it) at
          `<subdomain>.<domain>`. When `false`, Jellyfin's ports are opened on the LAN instead.
        '';
      };

      subdomain = lib.mkOption {
        type = lib.types.str;
        default = "jellyfin";
        description = "Subdomain Jellyfin is served at when `caddy` is enabled.";
      };

      backupDir = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/mnt/Apps/homelab";
        description = ''
          Parent directory to snapshot the data dir into nightly, as `<backupDir>/jellyfin`, overwriting
          the previous run - see the backup process notes above. Forwarded from `host.backupDir` by
          `modules/default.nix`. Must be outside `/var/lib/jellyfin`. `null` disables backups.
        '';
      };

      backupTime = lib.mkOption {
        type = lib.types.str;
        default = "01:00";
        example = "Sun 02:30";
        description = ''
          When the nightly `backupDir` snapshot runs, as a systemd `OnCalendar` expression. The
          service is stopped for the duration of the run, so pick a time nobody is streaming.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # Enable Jellyfin media server
      # - openFirewall opens TCP 8096,8920 and UDP 1900,7359 (discovery). Left closed when fronted
      #   by services.native.caddy on the same host — Caddy reaches it over loopback, and LAN clients
      #   go through Caddy's TLS instead of hitting Jellyfin's HTTP port directly.
      services.jellyfin = {
        enable = true;
        openFirewall = !cfg.caddy;
      };

      environment.systemPackages = [
        pkgs.jellyfin               # Jellyfin core
        pkgs.jellyfin-web           # Jellyfin web client support
        pkgs.jellyfin-ffmpeg        # Jellyfin codecs bundle
      ];

      # Add access to hardware acceleration for transcoding
      # - https://wiki.nixos.org/wiki/Immich#Enabling_Hardware_Accelerated_Video_Transcoding
      # - https://jellyfin.org/docs/general/administration/hardware-acceleration/intel#linux-setups
      users.users.jellyfin.extraGroups = [ "video" "render" "users" ];

      # Install the file if it doesn't exist
      files.any."/var/lib/jellyfin/config/network.xml" = {
        user = "jellyfin";
        group = "jellyfin";
        weakCopy = ''
          <?xml version="1.0" encoding="utf-8"?>
          <NetworkConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
            <BaseUrl />
            <EnableHttps>false</EnableHttps>
            <RequireHttps>false</RequireHttps>
            <InternalHttpPort>${toString cfg.port}</InternalHttpPort>
            <InternalHttpsPort>8920</InternalHttpsPort>
            <PublicHttpPort>${toString cfg.port}</PublicHttpPort>
            <PublicHttpsPort>8920</PublicHttpsPort>
            <AutoDiscovery>true</AutoDiscovery>
            <EnableUPnP>false</EnableUPnP>
            <EnableIPv4>true</EnableIPv4>
            <EnableIPv6>false</EnableIPv6>
            <EnableRemoteAccess>false</EnableRemoteAccess>
            <LocalNetworkSubnets />
            <LocalNetworkAddresses>127.0.0.1</LocalNetworkAddresses>
            <KnownProxies>127.0.0.1</KnownProxies>
            <IgnoreVirtualInterfaces>true</IgnoreVirtualInterfaces>
            <VirtualInterfaceNames>
              <string>veth</string>
            </VirtualInterfaceNames>
            <EnablePublishedServerUriByRequest>false</EnablePublishedServerUriByRequest>
            <PublishedServerUriBySubnet />
            <RemoteIPFilter />
            <IsRemoteIPFilterBlacklist>false</IsRemoteIPFilterBlacklist>
          </NetworkConfiguration>
        '';
      };
    }

    # Nightly stop -> rsync -> start snapshot of the data dir
    # - Runs as root since it has to stop/start the service; rsync -a keeps jellyfin's ownership
    # - The EXIT trap restarts jellyfin even if rsync fails, but only if it was running beforehand
    # - No wantedBy on the service itself so it never fires (and takes jellyfin down) at boot
    (lib.mkIf (cfg.backupDir != null) (let
      dataDir = config.services.jellyfin.dataDir;
      logDir = config.services.jellyfin.logDir;
      backupDir = "${cfg.backupDir}/jellyfin";
    in {
      assertions = [
        { assertion = !(lib.hasPrefix "${dataDir}/" "${backupDir}/");
          message = "services.native.jellyfin.backupDir must be outside ${dataDir}"; }
      ];

      # Have services.native.alerts watch this backup
      services.native.alerts.enable = lib.mkDefault true;
      services.native.alerts.backup.services = [ "jellyfin" ];

      systemd.tmpfiles.settings."10-jellyfin-backup".${backupDir}.d = {
        user = "jellyfin";
        group = "jellyfin";
        mode = "0770";
      };

      systemd.services.backup-jellyfin = {
        description = "Backup Jellyfin data dir";
        path = [ pkgs.rsync config.systemd.package ];
        serviceConfig.Type = "oneshot";
        script = ''
          set -euo pipefail
          if systemctl is-active --quiet jellyfin.service; then
            trap 'systemctl start jellyfin.service' EXIT
            systemctl stop jellyfin.service
          fi
          rsync -a --delete ${lib.optionalString (lib.hasPrefix "${dataDir}/" logDir)
            "--exclude=/${lib.removePrefix "${dataDir}/" logDir}/"} \
            ${dataDir}/ ${backupDir}/
        '';
      };

      systemd.timers.backup-jellyfin = {
        description = "Backup Jellyfin nightly";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.backupTime;
          Persistent = true;
        };
      };
    }))

    # Add a caddy proxy config for DNS subdomain resolution
    (lib.mkIf cfg.caddy {
      services.native.caddy.enable = lib.mkDefault true;
      services.native.caddy.proxies = [ { inherit (cfg) subdomain port; } ];
    })
  ]);
}
