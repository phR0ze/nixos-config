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
            description = lib.mdDoc ''
              Whether to open the firewall for the Portainer UI port. Defaults to closed — the
              container already mounts the Docker/podman socket (root-equivalent host access via
              spawning a privileged container through it), so reaching the UI at all should be a
              deliberate per-machine choice, not an inherited default.
            '';
            type = types.bool;
            default = false;
          };

          # Fixed subnet/IP rather than netavark's auto-IPAM — see cfg.subnet/cfg.ip's
          # description in options/types/service.nix for why (netavark's stale-DNAT-rule cleanup
          # bug, containers/podman#27516).
          subnet = lib.mkOption {
            description = lib.mdDoc "Fixed CIDR for Portainer's isolated podman network";
            type = types.str;
            default = "10.89.105.0/24";
          };

          ip = lib.mkOption {
            description = lib.mdDoc "Fixed IP address (within `subnet`) for the Portainer container";
            type = types.str;
            default = "10.89.105.2";
          };
        };
      };
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {

    # Enable podman support
    virtualisation.podman.enable = true;

    # Create persistent data directory for backup purposes
    # - Args: type, path, mode, user, group, expiration
    # - No age specified, i.e `-` defaults to infinite
    systemd.tmpfiles.rules = [
      "d /var/lib/${cfg.name}/data 0750 root root -"
    ];

    # Optionally allow the UI port through the firewall
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    # Generate the "podman-${cfg.name}" service unit for the container
    # - The Docker/podman socket mount below is the actual privilege boundary — anyone who can reach
    #   it can spawn a privileged container and mount the host filesystem through it, so treat the UI
    #   itself as root-equivalent access regardless of anything set here.
    # - `--privileged` was previously set on top of that and is dropped: it grants the *container
    #   process* full capabilities/device access and disables seccomp/AppArmor confinement, none of
    #   which Portainer's socket-based container management actually needs — it only widened what a
    #   compromised Portainer process (before ever touching the socket) could do for free.
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
      extraOptions = [ "--security-opt=no-new-privileges" "--ip=${cfg.ip}" ];
    };

    # Create podman network and extend service to use it
    systemd.services."podman-network-${cfg.name}" = f.createContNetwork { name = cfg.name; subnet = cfg.subnet; };
    systemd.services."podman-${cfg.name}" = f.extendContService { name = cfg.name; };
  };
}
