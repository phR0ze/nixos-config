# LXConsole configuration
# - https://github.com/PenningLabs/lxconsole
#
# ### Description
# lxconsole is an open source python application that uses flask as a framework and provides a 
# web-based user interface capable of managing mutiple Incus and LXD servers from a single location. 
# 
# - Connect and manage multiple servers
# - Create container and virtual machine instances from either a from or JSON input
# - Start, stop, rename and delete instances
# - Copy instances to create new instances
# - Create, restore and delete snapshots of instances
# - Create instances from snapshots
# - Download container and virtual machine images to hosts
#
# ### Deployment Features
# -
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, t, ... }: with lib.types;
let
  cfg = config.homelab.lxconsole;
  app = config.homelab.lxconsole.app;
  appOpts = (import ../types/app.nix { inherit lib; }).appOpts;
in
{
  options = {
    homelab.lxconsole= {
      enable = lib.mkEnableOption "Deploy container based LXConsole";

      app = lib.mkOption {
        description = lib.mdDoc "Containerized app options";
        type = types.submodule appOpts;
        default = {
          name = "lxconsole";
          user = {
            name = args.username;
            uid = config.users.users.${args.username}.uid;
            gid = config.users.groups."users".gid;
          };
          nic = {
            name = config.networking.vnic0;
            ip = "192.168.1.40";
            port = 80;
          };
        };
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
    networking.bridge.enable = true;
    #virtualization.incus.enable = true;
    virtualization.podman.enable = true;

    # Create persistent directories for application
    # - Args: type, path, mode, user, group, expiration
    # - No group specified, i.e `-` defaults to root
    # - No age specified, i.e `-` defaults to infinite
    systemd.tmpfiles.rules = [
      "d /var/lib/${app.name} 0750 ${toString app.user.uid} ${toString app.user.gid} -"
      "d /var/lib/${app.name}/backups 0750 ${toString app.user.uid} ${toString app.user.gid} -"
      "d /var/lib/${app.name}/certs 0750 ${toString app.user.uid} ${toString app.user.gid} -"
      "d /var/lib/${app.name}/instance 0750 ${toString app.user.uid} ${toString app.user.gid} -"
    ];

    # Generate the "podman-${app.name}" service unit for the container
    virtualisation.oci-containers.containers."${app.name}" = {
      image = "docker.io/penninglabs/lxconsole:latest";
      autoStart = true;
      hostname = "${app.name}";
      ports = [
        "${app.nic.ip}:${toString app.nic.port}:5000"     # Web UI
      ];
      volumes = [
        "/var/lib/${app.name}/backups:/opt/lxconsole/backups:rw"
        "/var/lib/${app.name}/certs:/opt/lxconsole/certs:rw"
        "/var/lib/${app.name}/instance:/opt/lxconsole/instance:rw"
      ];
      extraOptions = [
        "--network=${app.name}"                           # set the network to use
        #"--ip=${app.name}"                                # set the ip to use
      ];
    };

    # Setup firewall exceptions
    networking.firewall.interfaces."${app.name}".allowedTCPPorts = [
      app.nic.port
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
