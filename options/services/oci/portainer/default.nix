# Portainer configuration
# - [Portainer homepage](https://www.portainer.io/)
#
# ### Description
# Portainer is a Container Management tool for Docker, Podman and Kubernetes. It provides a nice
# intuitive graphical user interface for working with containers or compose based containers. It
# provides a library of maintained container configurations to make installing new software simple
# and fun.
#
# - Simple, self-service UI
# - Self-hosted so you're in control
#
# ### Alternatives
# - Compose2Nix converts docker compose files into NixOS configuration
#
# ### Deployment Details
# - App data is persisted at /var/lib/portainer/data
# - Get status with: `systemctl status podman-portainer`
# - Browse to: http://<IP>:<port>
# --------------------------------------------------------------------------------------------------
{ config, lib, f, ... }: with lib.types;
let
  cfg = config.services.oci.portainer;
in
{
  options = {
    services.oci.portainer = lib.mkOption {
      description = lib.mdDoc "Portainer service options";
      type = types.submodule {
        options = {
          enable = lib.mkEnableOption "Install and configure Portainer container management UI";

          name = lib.mkOption {
            description = lib.mdDoc "Service name used for container and network naming";
            type = types.str;
            default = "portainer";
          };

          tag = lib.mkOption {
            description = lib.mdDoc "Portainer CE image tag to use";
            type = types.str;
            default = "lts";
            example = "2.21.4";
          };

          port = lib.mkOption {
            description = lib.mdDoc "Host port to expose the Portainer UI on";
            type = types.port;
            default = 9000;
          };

          openFirewall = lib.mkOption {
            description = lib.mdDoc "Whether to open the firewall for the Portainer UI port";
            type = types.bool;
            default = true;
          };
        };
      };
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {

    # Enable podman support
    apps.system.podman.enable = true;

    # Create persistent data directory for backup purposes
    # - Args: type, path, mode, user, group, expiration
    # - No age specified, i.e `-` defaults to infinite
    systemd.tmpfiles.rules = [
      "d /var/lib/${cfg.name}/data 0750 root root -"
    ];

    # Optionally allow the UI port through the firewall
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    # Generate the "podman-${cfg.name}" service unit for the container
    # Portainer runs as root (--privileged) to manage the container runtime
    virtualisation.oci-containers.containers."${cfg.name}" = {
      image = "portainer/portainer-ce:${cfg.tag}";
      autoStart = true;
      hostname = "${cfg.name}";
      networks = [ cfg.name ];                  # Isolated app specific network
      ports = [ "${toString cfg.port}:9000" ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "/var/lib/${cfg.name}/data:/data"
      ];
      extraOptions = [ "--privileged" ];
    };

    # Create podman network and extend service to use it
    systemd.services."podman-network-${cfg.name}" = f.createContNetwork cfg.name;
    systemd.services."podman-${cfg.name}" = f.extendContService { name = cfg.name; };
  };
}
