# OneUp configuration
# - https://github.com/phR0ze/oneup
#
# ### Description
# Flutter application for tracking points
#
# ### Deployment Features
# - Get status with: `systemctl status podman-oneup`
# --------------------------------------------------------------------------------------------------
{ config, lib, args, pkgs, f, ... }: with lib.types;
let
  cfg = config.services.oci.oneup;

  # OneUp already runs as a fixed non-root user (see `user = ...` below) with no root-then-drop
  # startup dance of its own, and persists everything under the one `/app/data` volume already
  # declared below — so unlike Homarr/Stirling-PDF (PUID/PGID entrypoints, root-owned startup
  # writes) it's a safe candidate for Newt's hardening baseline. Turn any of these off if a future
  # OneUp release needs a capability or writes somewhere outside /app/data and fails to start.
  defaults = (f.getService args "oneup") // {
    capDropAll = true;
    noNewPrivileges = true;
    readOnlyRootfs = true;
  };
in
{
  imports = [ (import ../../types/service_base.nix { inherit config lib pkgs f cfg; }) ];

  options = {
    services.oci.oneup = lib.mkOption {
      description = lib.mdDoc "OneUp service options";
      type = types.submodule {
        imports = [ (import ../../types/service.nix { inherit lib defaults; }) ];
      };
      default = defaults;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      virtualisation.podman.enable = true;
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
        ports = [ "127.0.0.1:${toString cfg.port}:8080" ];  # Not exposed on LAN; front with services.raw.caddy
        volumes = [ "/var/lib/${cfg.name}/data:/app/data:rw" ];
        environment = { "PORT" = "8080"; };
        extraOptions = lib.optionals cfg.capDropAll [ "--cap-drop=ALL" ]
          ++ lib.optionals cfg.noNewPrivileges [ "--security-opt=no-new-privileges" ]
          ++ lib.optionals cfg.readOnlyRootfs [ "--read-only" "--tmpfs=/tmp" ];
      };

      # Create podmane network and extend service to use it
      systemd.services."podman-network-${cfg.name}" = f.createContNetwork cfg.name;
      systemd.services."podman-${cfg.name}" = f.extendContService { name = cfg.name; };
    })

    # Contribute a proxy entry to services.raw.caddy.proxies rather than requiring it be listed
    # separately in the machine's configuration.nix
    (lib.mkIf (cfg.enable && cfg.subdomain != null) {
      services.raw.caddy.proxies = [
        { inherit (cfg) subdomain port; }
      ];
    })
  ];
}
