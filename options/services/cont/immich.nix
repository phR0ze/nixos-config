# Immich
#
# ### Description
# Immich is a Self-hosted photo and video mangement solution to easily back up, organize and manage 
# your photos on your own server. Immich helps you browse, seach and organize your photos and videos 
# with ease, without sacrificing your privacy.
#
# ### References
# 
# --------------------------------------------------------------------------------------------------
{ config, lib, args, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.services.cont.immich;
  defaults = (f.getService args "immich" 2003 2003);
in
{
  imports = [ (import ../../types/service_base.nix { inherit config lib pkgs f cfg; }) ];

  options = {
    services.cont.immich = lib.mkOption {
      description = lib.mdDoc "Immich service options";
      type = types.submodule { imports = [ (import ../../types/service.nix { inherit lib defaults; }) ]; };
      default = defaults;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      #{ assertion = (cfg ? "debug"); message = "echo '${builtins.toJSON cfg}' | jq"; }
      { assertion = (cfg.user.pass != null && cfg.user.pass != "");
        message = "Postgres pass not set, please set 'service.cont.${cfg.name}.user.pass'"; }
    ];
    virtualisation.podman.enable = true;

    # Add access to hardware acceleration for transcoding
    # - https://wiki.nixos.org/wiki/Immich
    users.groups.${cfg.user.group} = f.createContGroup cfg.user;
    users.users.${cfg.user.name} = f.createContUser cfg.user // { extraGroups = [ "video" "render" ]; };

    # Create persistent directories for application
    systemd.tmpfiles.rules = [
      "d /var/lib/${cfg.name} 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      "d /var/lib/${cfg.name}/data 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      "d /var/lib/${cfg.name}/cache 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      "d /var/lib/${cfg.name}/postgres 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
    ];

    # Create a podman network for the service
    systemd.services."podman-network-${cfg.name}" = f.createContNetwork cfg.name;

    # Create the "podman-${cfg.name}-server" service
    virtualisation.oci-containers.containers."${cfg.name}-server" = {
      hostname = "immich-server";               # expected hostname
      image = "ghcr.io/immich-app/${cfg.name}-server:${cfg.tag}";
      autoStart = true;
      ports = [ "${(f.toIP config.net.primary.ip).address}:${toString cfg.port}:2283" ];
      volumes = [
        "/var/lib/${cfg.name}/data:/data:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        "DB_USERNAME" = "postgres";             # Username, "postgres" is the suggested value
        "DB_PASSWORD" = "${cfg.user.pass}";     # Postgres secret e.g. random string only containing `A-Za-z0-9`
        "DB_DATA_LOCATION" = "./postgres";      # Database files storage location
        "DB_DATABASE_NAME" = "immich";          # Database, "immich" is the suggested value
      }; 
      extraOptions = [ "--network=${cfg.name}" ];
    };

    # Create the "podman-${cfg.name}-machine-learning" service
    virtualisation.oci-containers.containers."${cfg.name}-machine-learning" = {
      hostname = "immich-machine-learning";     # name server is looking for
      image = "ghcr.io/immich-app/${cfg.name}-machine-learning:${cfg.tag}";
      autoStart = true;
      volumes = [ "/var/lib/${cfg.name}/cache:/cache:rw" ];
      extraOptions = [ "--network=${cfg.name}" ];
    };

    # Create the "podman-${cfg.name}-redis" service
    virtualisation.oci-containers.containers."${cfg.name}-redis" = {
      hostname = "redis";                       # name server is looking for
      image = "docker.io/valkey/valkey:8-bookworm@sha256:fea8b3e67b15729d4bb70589eb03367bab9ad1ee89c876f54327fc7c6e618571";
      autoStart = true;
      extraOptions = [ "--network=${cfg.name}" ];
    };

    # Create the "podman-${cfg.name}-redis" service
    virtualisation.oci-containers.containers."${cfg.name}-postgres" = {
      hostname = "database";                    # name server is looking for
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:41eacbe83eca995561fe43814fd4891e16e39632806253848efaf04d3c8a8b84";
      autoStart = true;
      volumes = [ "/var/lib/${cfg.name}/postgres:/var/lib/postgresql/data:rw" ];
      environment = {
        "POSTGRES_DB" = "immich";               # Database, "immich" is the suggested value
        "POSTGRES_USER" = "postgres";           # Username, "postgres" is the suggested value
        "DB_STORAGE_TYPE" = "HDD";              # Specify that we are not using SSDs
        "POSTGRES_PASSWORD" = "${cfg.user.pass}"; # Postgres secret e.g. random string only containing `A-Za-z0-9`
        "POSTGRES_INITDB_ARGS" = "--data-checksums";
      };
      extraOptions = [
        "--network=${cfg.name}"                 # Use the same network as immich
        "--shm-size=128mb"                      # Increase the shared memory size, default is 64mb
      ];
    };

    networking.firewall.interfaces.${machine.net.bridge.name}.allowedTCPPorts = [ cfg.port ];

    # Extend the services to depend on the podman network
    systemd.services."podman-${cfg.name}-server" = f.extendContService {
      name = cfg.name; deps = [ "redis" "postgres" ]; };
    systemd.services."podman-${cfg.name}-machine-learning" = f.extendContService { name = cfg.name; };
    systemd.services."podman-${cfg.name}-redis" = f.extendContService { name = cfg.name; };
    systemd.services."podman-${cfg.name}-postgres" = f.extendContService { name = cfg.name; };
  };
}
