# qBittorrent configuration
# - https://www.qbittorrent.org/
# - https://github.com/qbittorrent/qBittorrent/
#
# ### Description
# qBittorrent is a bittorrent client programmed in C++/Qt that uses libtorrent. It is an open source
# cross platform alternative to the likes of uTorrent.
# 
# - Polished uTorrent like interface
# - No Ads, modern features
# - Remote Web Interface
# - Sequential downloading
#
# ### Deployment Features
# - App has outbound access to the internet, but block from outbound connections to the LAN
# - App is visiable on the LAN, with a dedicated host macvlan and static IP, for inbound connections
#
# ### Initial Setup
# - Web UI temporary password for `admin` user is printed to the container log. You must change it in
#   the Web UI or you'll have a new one on every boot.
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, t, ... }: with lib.types;
let
  cfg = config.homelab.qbittorrent;
  app = config.homelab.qbittorrent.app;
  appOpts = (import ../types/app.nix { inherit lib; }).appOpts;
in
{
  options = {
    homelab.qbittorrent = {
      enable = lib.mkEnableOption "Deploy container based qBittorrent";

      app = lib.mkOption {
        description = lib.mdDoc "Containerized app options";
        type = types.submodule appOpts;
        default = {
          name = "qbittorrent";
          user = {
            name = args.username;
            uid = config.users.users.${args.username}.uid;
            gid = config.users.groups."users".gid;
          };
          nic = {
            name = args.nic0;
            ip = "192.168.1.41";
            port = 80;
          };
        };
      };

      downloads = lib.mkOption {
        description = lib.mdDoc "Path where downloads should be stored";
        type = types.str;
        default = "/var/lib/qbittorrent/downloads";
      };
    };
  };
 
  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = (app.name != null && app.name != "");
        message = "Application name not specified, please set 'app.name'"; }
      { assertion = (app.user.name != null && app.user.name != "");
        message = "Application user name not specified, please set 'app.user.name'"; }
      { assertion = (app.user.uid != null);
        message = "Application user uid not specified, please set 'app.user.uid'"; }
      { assertion = (app.user.gid != null);
        message = "Application user gid not specified, please set 'app.user.gid'"; }
      { assertion = (app.nic.name != null && app.nic.name != "");
        message = "Application nic name not specified, please set 'app.nic.name'"; }
      { assertion = (app.nic.ip != null);
        message = "Application nic ip not specified, please set 'app.nic.ip'"; }
      { assertion = (app.nic.port != null);
        message = "Application nic port not specified, please set 'app.nic.port'"; }
    ];

    # Requires podman virtualization to be configured
    virtualization.podman.enable = true;

    # Create persistent directories for application
    # - Args: type, path, mode, user, group, expiration
    # - No group specified, i.e `-` defaults to root
    # - No age specified, i.e `-` defaults to infinite
    systemd.tmpfiles.rules = [
      "d /var/lib/${app.name} 0750 ${toString app.user.uid} ${toString app.user.gid} -"
      "d ${cfg.downloads} 0750 ${toString app.user.uid} ${toString app.user.gid} -"
    ];

    # Generate the "podman-${app.name}" service unit for the container
    # Linux server containers are nice in that they allow for user mapping with PUID, PGID
    virtualisation.oci-containers.containers."${app.name}" = {
      image = "lscr.io/linuxserver/qbittorrent:latest";
      autoStart = true;
      hostname = "${app.name}";
      ports = [
        "${app.nic.ip}:${toString app.nic.port}:8080"        # Web UI
        "${app.nic.ip}:6881:6881/tcp" "${app.nic.ip}:6881:6881/udp"   # torrenting ports
      ];
      volumes = [
        "/var/lib/${app.name}:/config:rw"                     # configuration directory
        "${cfg.downloads}:/downloads:rw"                      # downloads directory
      ];
      environment = {
        "PUID" = "${toString app.user.uid}";                  # set user id to use
        "PGID" = "${toString app.user.gid}";                  # set group id to use
        "TORRENTING_PORT" = "6881";                           # port for torrenting
      };
      extraOptions = [
        "--network=${app.name}"                               # set the network to use
      ];
    };

    # Setup firewall exceptions
    networking.firewall.interfaces.${app.name}.allowedTCPPorts = [
      app.nic.port
      6881
    ];

    # Create host macvlan with a dedicated static IP for the app to port forward to
    networking = {
      macvlans.${app.name} = {
        interface = "${app.nic.name}";
        mode = "bridge";
      };
      interfaces.${app.name}.ipv4.addresses = [
        { address = "${app.nic.ip}"; prefixLength = 32; }
      ];
    };

    # Create a dedicated container network to keep the app isolated from other services
    systemd.services."podman-network-${app.name}" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = [
          "podman network rm -f ${app.name}"
        ];
      };
      script = ''
        if ! podman network exists ${app.name}; then
          podman network create ${app.name}
        fi
      '';
    };

    # Add additional configuration to the above generated app service unit i.e. acts as an overlay.
    # We simply match the name here that is autogenerated from the oci-container directive.
    systemd.services."podman-${app.name}" = {
      wantedBy = [ "multi-user.target" ];

      # Trigger the creation of the app macvlan if not already and wait for it. network-addresses... 
      # applies the static IP address to the macvlan which it waits to be created for, thus by 
      # waiting on it we ensure the macvlan is up and running with an IP address.
      wants = [
        "network-online.target"
        "network-addresses-${app.name}.service"
        "podman-network-${app.name}.service"
      ];
      after = [
        "network-online.target"
        "network-addresses-${app.name}.service"
        "podman-network-${app.name}.service"
      ];

      serviceConfig = {
        Restart = "always";
        WorkingDirectory = "/var/lib/${app.name}";
      };
    };
  };
}
