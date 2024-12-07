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
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
#  userType = (import ../types/user.nix {
#    inherit options config lib pkgs args;
#  }).userType;

  app = config.homelab.qbittorrent;
in
{
  options = {
    homelab.qbittorrent = rec {
      enable = lib.mkEnableOption "Deploy container based qBittorrent";

      name = lib.mkOption {
        description = lib.mdDoc "App name to use for supporting components";
        type = types.str;
        default = "qbittorrent";
      };

#      user = lib.mkOption {
#        description = lib.mdDoc "User to use for the application";
#        type = config.types.user;
#      };

      uid = lib.mkOption {
        description = lib.mdDoc "User id to use for the application";
        type = types.int;
        default = config.users.users.${args.username}.uid;
      };

      gid = lib.mkOption {
        description = lib.mdDoc "Group id to use for the application";
        type = types.int;
        default = config.users.groups."users".gid;
      };

      nic = lib.mkOption {
        description = lib.mdDoc "Parent NIC for the app macvlan";
        type = types.str;
        default = "${args.nic0}";
      };

      ip = lib.mkOption {
        description = lib.mdDoc "IP address to use for the app macvlan";
        type = types.str;
        default = "192.168.1.41";
      };

      port = lib.mkOption {
        description = lib.mdDoc "Port to use for Web Interface on the macvlan";
        type = types.port;
        default = 80;
        example = {
          port = 80;
        };
      };

      downloads = lib.mkOption {
        description = lib.mdDoc "Path where downloads should be stored";
        type = types.str;
        default = "/var/lib/${app.name}/downloads";
      };
    };
  };
 
  config = lib.mkIf app.enable {
    assertions = [
      {
        assertion = ("${app.nic}" != "");
        message = "Application parent NIC not specified, please set 'nic'";
      }
    ];

    # Requires podman virtualization to be configured
    virtualization.podman.enable = true;

    # Create persistent directories for application
    # - Args: type, path, mode, user, group, expiration
    # - No group specified, i.e `-` defaults to root
    # - No age specified, i.e `-` defaults to infinite
    systemd.tmpfiles.rules = [
      "d /var/lib/${app.name} 0750 ${toString app.uid} ${toString app.gid} -"
      "d ${app.downloads} 0750 ${toString app.uid} ${toString app.gid} -"
    ];

    # Generate the "podman-${app.name}" service unit for the container
    virtualisation.oci-containers.containers."${app.name}" = {
      image = "lscr.io/linuxserver/qbittorrent:latest";
      autoStart = true;
      hostname = "${app.name}";
      ports = [
        "${app.ip}:${toString app.port}:8080"                 # Web UI
        "${app.ip}:6881:6881/tcp" "${app.ip}:6881:6881/udp"   # torrenting ports
      ];
      volumes = [
        "/var/lib/${app.name}:/config:rw"                     # configuration directory
        "${app.downloads}:/downloads:rw"                      # downloads directory
      ];
      environment = {
        "PUID" = "${toString app.uid}";                  # set user id to use
        "PGID" = "${toString app.gid}";                  # set group id to use
        "TORRENTING_PORT" = "6881";                           # port for torrenting
      };
      extraOptions = [
        "--network=${app.name}"                               # set the network to use
      ];
    };

    # Setup firewall exceptions
    networking.firewall.interfaces.${app.name}.allowedTCPPorts = [
      app.port
      6881
    ];

    # Create host macvlan with a dedicated static IP for the app to port forward to
    networking = {
      macvlans.${app.name} = {
        interface = "${app.nic}";
        mode = "bridge";
      };
      interfaces.${app.name}.ipv4.addresses = [
        { address = "${app.ip}"; prefixLength = 32; }
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
