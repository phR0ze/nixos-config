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
  host = config.host;
  cfg = config.services.nspawn.portainer;

  filtered = builtins.filter (x: x.name == "portainer") host.services;
  defaults = if (builtins.length filtered > 0) then builtins.elemAt filtered 0 else {};

  # NOTE: for hashedPasswordFile to resolve here, the container's own module list (below) needs
  # inputs.nixos-files.nixosModules.default imported too, so config.sops.secrets exists inside
  # the container's separate module tree -- not done yet, since this module is currently unused
  # (see caller note below).
  modules_users = { lib, config, host, ...}: {
    users.users.root = if host.secrets != null
      then { hashedPasswordFile = lib.mkForce "/run/files/user-passwordhash"; }
      else { initialPassword = lib.mkForce host.user.pass; };
    users.users.${host.user.name} = {
      uid = 1000;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    } // (if host.secrets != null
      then { hashedPasswordFile = lib.mkForce "/run/files/user-passwordhash"; }
      else { initialPassword = lib.mkForce host.user.pass; });
    users.groups."${host.user.group}".gid = 100;
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
        message = "Requires 'host.services' contain a config for this service"; }
      { assertion = (host.net.bridge.enable);
        message = "Requires 'host.net.bridge.enable = true;' to work correctly"; }
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
        imports = [ ../../../modules/new_users.nix { inherit lib host; } ];
        config = {
          system.stateVersion = host.nix.minVer;

          # Allow the server port through the firewall
          networking.firewall.allowedTCPPorts = [ cfg.opts.port ];
        };
      };
    };
  };
}
