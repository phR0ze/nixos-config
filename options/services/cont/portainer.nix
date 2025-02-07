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
# ### Deployment Features
# - Service has outbound access to the internet
# - Service is blocked from outbound connections to the LAN
# - Service has dedicated podman bridge network with port forwarding to dedicated host macvlan
# - Service is visible on the LAN, with a dedicated host macvlan and static IP, for inbound connections
# - Service data is persisted at /var/lib/$SERVICE
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.raw.portainer;
  machine = config.machine;
  filtered = builtins.filter (x: x.name == "portainer" && x.type == "cont") machine.services;
  defaults = if (builtins.length filtered > 0) then builtins.elemAt filtered 0 else {};
in
{
  options = {
    services.raw.portainer = {
      enable = lib.mkEnableOption "Install and configure portainer";
      opts = lib.mkOption {
        description = lib.mdDoc "Containerized service options";
        type = types.submodule (import ../../types/service.nix { inherit lib; });
        default = defaults;
      };
      version = lib.mkOption {
        description = lib.mdDoc "Portainer-CE version to use";
        type = types.str;
        default = "latest";
      };
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    assertions = [
      { assertion = (builtins.length filtered > 0);
        message = "Requires 'machine.services' contain a config for this service"; }
      { assertion = (machine.net.bridge.enable);
        message = "Requires 'machine.net.bridge.enable = true;' to work correctly"; }
      { assertion = (cfg.opts.nic.link != "");
        message = "Requires 'opts.nic.link' be set to the primary network interface"; }
      { assertion = (cfg.opts.nic.ip != "");
        message = "Requires 'opts.nic.ip' be set to a static IP address"; }
      { assertion = (cfg.opts.port != 0); message = "Requires 'opts.port' be set"; }
    ];

  };
}
