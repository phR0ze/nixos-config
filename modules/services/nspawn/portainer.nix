# Portainer Nspawn container
#
# ### Description
# ?
#
# ### Deployment Features
# - Service has a full NixOS stack minus the kernel
# - Service is a full LAN participant with its own static IP
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, inputs, ... }: with lib.types;
let
  host = config.host;
  cfg = config.services.nspawn.portainer;

  filtered = builtins.filter (x: x.name == "portainer") host.services;
  defaults = if (builtins.length filtered > 0) then builtins.elemAt filtered 0 else {};

  # Container-side user config: mirrors modules/system/users.nix's pattern, but parameterized
  # by the *container's own* `config`/`lib` (its module tree is entirely separate from the
  # host's) -- `inputs.nix-weave.nixosModules.default` must be imported into the container
  # below for `config.secret.files` to exist there. `host` closes over the *host's*
  # `config.host`, since the admin username/password/secrets file are the same as the host's.
  containerUsers = { config, lib }: {
    users.users.root = if host.secrets != null
      then { hashedPasswordFile = lib.mkForce config.secret.files."user-passwordhash".path; }
      else { initialPassword = lib.mkForce host.user.pass; };
    users.users.${host.user.name} = {
      uid = 1000;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    } // (if host.secrets != null
      then { hashedPasswordFile = lib.mkForce config.secret.files."user-passwordhash".path; }
      else { initialPassword = lib.mkForce host.user.pass; });
    users.groups."${host.user.group}".gid = 100;
  } // lib.optionalAttrs (host.secrets != null) {
    # Decrypted at activation to sops-nix's default path
    # (config.secret.files."user-passwordhash".path, normally /run/secrets/user-passwordhash),
    # never touching the Nix store.
    secret.files."user-passwordhash" = {
      sopsFile = host.secrets;
      key = "user/passwordHash";
    };
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
        imports = [ inputs.nix-weave.nixosModules.default ];
        config = lib.mkMerge [
          (containerUsers { inherit config lib; })
          {
            system.stateVersion = host.nix.minVer;

            # Allow the server port through the firewall
            networking.firewall.allowedTCPPorts = [ cfg.opts.port ];
          }
        ];
      };
    };
  };
}
