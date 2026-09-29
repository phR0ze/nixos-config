# OneUp configuration
# - https://github.com/phR0ze/oneup
#
# ### Description
# Flutter application for tracking points
#
# ### Deployment Features
# - Get status with: `systemctl status podman-oneup`
# --------------------------------------------------------------------------------------------------
{ config, lib, f, ... }:
let
  cfg = config.services.oci.oneup;
in
{
  options.services.oci.oneup = import ../../types/service.nix {
    inherit lib;
    defaults = {
      name = "oneup";
      caddy = true;
      subdomain = "oneup";
      capDropAll = true;
      noNewPrivileges = true;
      readOnlyRootfs = true;
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = f.ociAsserts cfg ++ [
        { assertion = cfg.caddy -> cfg.subdomain != null;
          message = "services.oci.oneup: 'caddy' requires 'subdomain' to be set";
        }
      ];

      virtualization.podman.enable = true;
      users.users.${cfg.user.name} = f.createUser cfg.user;
      users.groups.${cfg.user.group} = f.createGroup cfg.user;

      # Create persistent directories for application
      # - Args: type, path, mode, user, group, expiration
      # - No group specified, i.e `-` defaults to root
      # - No age specified, i.e `-` defaults to infinite
      systemd.tmpfiles.rules = [
        "d /var/lib/${cfg.name}/data 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      ];

      # Generate the "podman-${cfg.name}" service unit for the container
      virtualisation.oci-containers.containers."${cfg.name}" = {
        hostname = "${cfg.name}";
        user = "${toString cfg.user.uid}:${toString cfg.user.gid}";
        image = "ghcr.io/phr0ze/${cfg.name}:${cfg.tag}";
        autoStart = true;
        networks = [ cfg.name ];                  # Isolated app specific network
        # Loopback-only when fronted by Caddy, otherwise published on the LAN
        ports = [ "${lib.optionalString cfg.caddy "127.0.0.1:"}${toString cfg.port}:8080" ];
        volumes = [ "/var/lib/${cfg.name}/data:/app/data:rw" ];
        environment = { "PORT" = "8080"; };
        extraOptions = [ "--ip=${cfg.ip}" ]
          ++ lib.optionals cfg.capDropAll [ "--cap-drop=ALL" ]
          ++ lib.optionals cfg.noNewPrivileges [ "--security-opt=no-new-privileges" ]
          ++ lib.optionals cfg.readOnlyRootfs [ "--read-only" "--tmpfs=/tmp" ];
      };

      # Create podmane network and extend service to use it
      systemd.services."podman-network-${cfg.name}" = f.createContNetwork { name = cfg.name; subnet = cfg.subnet; };
      systemd.services."podman-${cfg.name}" = f.extendContService { name = cfg.name; };

      networking.firewall.allowedTCPPorts = lib.optional (!cfg.caddy) cfg.port;
    }

    # Contribute a proxy entry to services.native.caddy.proxies rather than requiring it be listed
    # separately in the machine's configuration.nix
    (lib.mkIf cfg.caddy {
      services.native.caddy.enable = lib.mkDefault true;
      services.native.caddy.proxies = [
        { inherit (cfg) subdomain port; }
      ];
    })
  ]);
}
