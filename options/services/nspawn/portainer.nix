# Portainer Nspawn container
#
# ### Description
# ?
#
# ### Deployment Features
# - Service has a full NixOS stack minus the kernel
# - Service is a full LAN participant with its own static IP
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.services.nspawn.portainer;

  filtered = builtins.filter (x: x.name == "portainer") machine.services;
  defaults = if (builtins.length filtered > 0) then builtins.elemAt filtered 0 else {};

  modules_users = { lib, machine, ...}: {
    users.users.root.initialPassword = lib.mkForce machine.user.pass;
    users.users.${machine.user.name} = {
      uid = 1000;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      initialPassword = lib.mkForce machine.user.pass;
    };
    users.groups."users".gid = 100;
  };
in
{
  options = {
    services.nspawn.portainer = {
      enable = lib.mkEnableOption "Deploy nspawn container based Portainer";
      opts = lib.mkOption {
        description = lib.mdDoc "Containerized service options";
        type = types.submodule (import ../../types/service.nix { inherit lib; });
        default = defaults;
      };
    };
  };
 
  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = (builtins.length filtered > 0);
        message = "Requires 'machine.services' contain a config for this service"; }
      { assertion = (machine.net.bridge.enable);
        message = "Requires 'machine.net.bridge.enable = true;' to work correctly"; }
      { assertion = (cfg.opts.nic.link != "");
        message = "Requires 'opts.nic.link' be set to the bridge name"; }
      { assertion = (cfg.opts.nic.ip != "");
        message = "Requires 'opts.nic.ip' be set to a static IP address"; }
      { assertion = (cfg.opts.port != 0); message = "Requires 'opts.port' be set"; }
    ];

    # Host configuration for service
    #networking.firewall.allowedTCPPorts = [ cfg.opts.port ];

    # Container configuration for service
    containers.portainer = {
      autoStart = true;                     # Enable the systemd unit to be started on boot
      privateNetwork = true;                # Bind to local host bridge to get a presence on the LAN
      hostBridge = cfg.opts.nic.link;       # Host bridge name to bind to e.g. br0
      localAddress = cfg.opts.nic.ip;       # Static IP for the virtual adapter on the bridge

      config = { options, config, pkgs, lib, ...}: {
        imports = [ ../../../modules/new_users.nix { inherit lib machine; } ];
        config = {
          system.stateVersion = machine.nix.minVer;

          # Allow the server port through the firewall
          networking.firewall.allowedTCPPorts = [ cfg.opts.port ];
        };
      };
    };
  };
}
