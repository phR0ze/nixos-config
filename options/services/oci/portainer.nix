# Portainer configuration
# - [Portainer homepage](https://www.portainer.io/)
#
# ### Description
# Portainer is a Container Management tool for Docker, Podman and Kubernetes. It provides a nice 
# interuitive graphical user interface for working with containers or compose based containers. It 
# provides a library of maintained container configurations to make installing new software simple 
# and fun.
#
# - Simple, self-service UI
# - Self-hosted so your in control
#
# ### Alternatives
# - Compose2Nix converts docker compose files into NixOS configuration
#
# ### Notes
# - Get status with: `systemctl status podman-portainer`
# - UI accessible at 0.0.0.0:9000
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.services.oci.portainer;
  app = cfg.app;
  filtered = builtins.filter (x: x.name == "portainer" && x.type == "oci") machine.services;
  defaults = if (builtins.length filtered > 0) then builtins.elemAt filtered 0 else {};
in
{
  options = {
    services.oci.portainer = {
      enable = lib.mkEnableOption "Install and configure portainer";
      app = lib.mkOption {
        description = lib.mdDoc "Containerized service options";
        type = types.submodule (import ../../types/service.nix { inherit lib; });
        default = defaults;
      };
      version = lib.mkOption {
        description = lib.mdDoc "Portainer-CE version to use";
        type = types.str;
        default = "lts";
        example = "2.21.4";
      };
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    assertions = [
      { assertion = (builtins.length filtered > 0);
        message = "Requires that 'machine.services' contain a config for this service"; }
    ];

    # Ensure podman dependency is enabled
    virtualisation.podman.enable = true;

    # Portainer can optionally use 8000 for edge agents as well
    virtualisation.oci-containers.containers."${app.name}" = {
      image = "portainer/portainer-ce:${cfg.version}";
      cmd = [ "--base-url=/portainer" ];
      autoStart = true;
      hostname = "${app.name}";
      ports = [
        "9000:9000"     # HTTP UI access
        #"9443:9443"     # HTTPS UI access is not needed in internal home lab for test
      ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "portainer_data:/data"
      ];
      extraOptions = [
        "--privileged"
      ];
    };

    # Allow ports through firewall
    networking.firewall.allowedTCPPorts = [ 9000 9443 ];
  };
}
