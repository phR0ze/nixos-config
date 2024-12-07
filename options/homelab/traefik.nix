# Traefik configuration
# - https://doc.traefik.io/traefik/
# - https://github.com/traefik/traefik
#
# ### Description
# Traefik is a modern HTTP reverse proxy and load balancer that makes deploying microservices easy.
# Traefik integrates with your existing infrastructure components (Docker, Kubernetes, ...) and 
# configures itself automatically and dynamically. Pointing Traefik at your orchestrator should be 
# the only configuration step you need.
#
# - Continuously updates its configuration (No restarts needed)
# - Provides HTTPS to your microservices by leveraging Let's Encrypt (wildcard certificate support)
# - Provides metrics (Rest, Prometheus)
# - Keeps access logs (JSON, CLF)
# - Web UI
#
# ### Deployment Features
# - 
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  app = config.homelab.traefik;

  mainConfFile = pkgs.writeTextFile {
    name = "main.yaml";
    text = ''
      global:
        checkNewVersion: false
        sendAnonymousUsage: false
    '';
  };
 
in
{
  options = {
    homelab.traefik = {
      enable = lib.mkEnableOption "Deploy container based Traefik";

      name = lib.mkOption {
        description = lib.mdDoc "App name to use for supporting components";
        type = types.str;
        default = "traefik";
      };

      nic = lib.mkOption {
        description = lib.mdDoc "Parent NIC for the app macvlan";
        type = types.str;
        default = "${args.nic0}";
      };

      ip = lib.mkOption {
        description = lib.mdDoc "IP address to use for the app macvlan";
        type = types.str;
        default = "192.168.1.51";
      };

      port = lib.mkOption {
        description = lib.mdDoc "Port to use for Web Interface on the macvlan";
        type = types.port;
        default = 80;
        example = {
          port = 80;
        };
      };

      skipConfig = lib.mkOption {
        description = lib.mdDoc "Skip the default configuration to give a clean setup";
        type = types.bool;
        default = false;
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
      "d /var/lib/${app.name} 0750 ${args.username} - -"
      "d /var/lib/${app.name}/conf.d 0750 ${args.username} - -"
    ];

    # Generate the "podman-${app.name}" service unit for the container
    # https://doc.traefik.io/traefik/getting-started/quick-start/
    virtualisation.oci-containers.containers."${app.name}" = {
      image = "docker.io/traefik:v3.2";
      autoStart = true;
      hostname = "${app.name}";
      cmd = [
        "--providers.docker"                              # enable docker support
        "--providers.file.directory=/etc/traefik/conf.d"  # source configuration files
        "--api.insecure=true"                 # enable the Web UI, don't do in production
      ];
      ports = [
        "${app.ip}:${toString app.port}:80/tcp"
        "${app.ip}:443:443/tcp" "${app.ip}:443:443/udp"
        "8080:8080"                                       # Web UI
      ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:ro"
        "/var/lib/${app.name}:/etc/traefik/:ro"           # default location traefik searches for traefik.yaml
        #"./data/certs/:/var/traefik/certs/:rw"
        #"./config/conf.d/:/etc/traefik/conf.d/:ro"
      ];
      extraOptions = [
        "--network=${app.name}"
      ];
    };

    # Setup firewall exceptions
    networking.firewall.interfaces.${app.name}.allowedTCPPorts = [ app.port ];

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

      # Write the persisted configuration file
      preStart = ''
        if [ "${f.boolToIntStr app.skipConfig}" = "0" ]; then
          cp --force "${mainConfFile}" "/var/lib/${app.name}/conf.d/main.yaml"
          chmod 600 "/var/lib/${app.name}/conf.d/main.yaml"
        fi
      '';

      serviceConfig = {
        Restart = "always";
        WorkingDirectory = "/var/lib/${app.name}";
      };
    };
  };
}
