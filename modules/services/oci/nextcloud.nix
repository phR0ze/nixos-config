# Nextcloud configuration
#
# ### Description
#
# ### Deployment Features
# - Get status with: `systemctl status podman-nextcloud`
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.services.oci.nextcloud;
in
{
  options.services.oci.nextcloud = (import ../../types/service.nix {
    inherit lib; defaults = { name = "nextcloud"; };
  }) // {
    bridge = lib.mkOption {
      description = lib.mdDoc ''
        Name of the LAN bridge this service's port is opened on, see `devices.network.bridge.name`.
        Forwarded by modules/default.nix rather than read from `devices.*` directly.
      '';
      type = types.str;
      default = "br0";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = f.ociAsserts cfg;

    virtualisation.podman.enable = true;
    users.users.${cfg.user.name} = f.createUser cfg.user;
    users.groups.${cfg.user.group} = f.createGroup cfg.user;

    # Create persistent directories for application
    # - Args: type, path, mode, user, group, expiration
    # - No group specified, i.e `-` defaults to root
    # - No age specified, i.e `-` defaults to infinite
    systemd.tmpfiles.rules = [
      "d /var/lib/${cfg.name} 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      "d /var/lib/${cfg.name}/data 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
    ];

    # Generate the "podman-${cfg.name}" service unit for the container
    virtualisation.oci-containers.containers."${cfg.name}" = {
      image = "ghcr.io/phr0ze/${cfg.name}:${cfg.tag}";
      autoStart = true;
      hostname = "${cfg.name}";
      networks = [ cfg.name ];                  # Isolated app specific network
      ports = [ "${(f.toIP config.devices.network.primary.ip).address}:${toString cfg.port}:80" ];
      volumes = [ "/var/lib/${cfg.name}/data:/app/data:rw" ];
      extraOptions = [ "--ip=${cfg.ip}" ];
    };

    networking.firewall.interfaces.${cfg.bridge}.allowedTCPPorts = [ cfg.port ];

    # Create podmane network and extend service to use it
    systemd.services."podman-network-${cfg.name}" = f.createContNetwork { name = cfg.name; subnet = cfg.subnet; };
    systemd.services."podman-${cfg.name}" = f.extendContService cfg.name;
  };
}
