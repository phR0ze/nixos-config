# Immich
#
# ### Description
# Immich is a Self-hosted photo and video mangement solution to easily back up, organize and manage 
# your photos on your own server. Immich helps you browse, seach and organize your photos and videos 
# with ease, without sacrificing your privacy.
#
# ### Inspired by
# - [Suderman's work](https://github.com/suderman/nixos/blob/main/modules/nixos/default/options/immich.nix)
#
# ### References
# - There is no need for additional firewall rules if using a bridge network as it already has taken 
#   care of the isolation by injecting `-A NETAVARK_ISOLATION_3 -o ${network} -j DROP` into iptables
# --------------------------------------------------------------------------------------------------
{ config, lib, args, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.services.oci.immich;
  gpu = config.devices.gpu;
  defaults = (f.getService args "immich" 2003 2003);
in
{
  imports = [ (import ../../types/service_base.nix { inherit config lib pkgs f cfg; }) ];

  options = {
    services.oci.immich = lib.mkOption {
      description = lib.mdDoc "Immich service options";
      type = types.submodule { imports = [ (import ../../types/service.nix { inherit lib defaults; }) ]; };
      default = defaults;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = [
        #{ assertion = (cfg ? "debug"); message = "echo '${builtins.toJSON cfg}' | jq"; }
        { assertion = (cfg.user.pass != null && cfg.user.pass != "");
          message = "Postgres pass not set, please set 'service.oci.${cfg.name}.user.pass'"; }
      ];
      virtualisation.podman.enable = true;

      # Add access to hardware acceleration for transcoding
      # - https://wiki.nixos.org/wiki/Immich
      users.users.${cfg.user.name} = f.createUser cfg.user // {
        extraGroups = [ "video" "render" ]
          ++ lib.optionals (gpu.nvidia) [ "nvidia" ];
      };

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
        user = "${toString cfg.user.uid}:${toString cfg.user.gid}";
        image = "ghcr.io/immich-app/${cfg.name}-server:${cfg.tag}";
        autoStart = true;
        networks = [ cfg.name ];                  # Isolated app specific network
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
      };

      # Create the "podman-${cfg.name}-machine-learning" service
      virtualisation.oci-containers.containers."${cfg.name}-machine-learning" = let
        tag = if (gpu.nvidia) then "${cfg.tag}-cuda"
          else (if (gpu.amd) then "${cfg.tag}-rocm"
            else (if (gpu.intel) then "${cfg.tag}-openvino"
              else "${cfg.tag}"));
      in {
        hostname = "immich-machine-learning";     # name server is looking for
        #user = "${toString cfg.user.uid}:${toString cfg.user.gid}";
        image = "ghcr.io/immich-app/immich-machine-learning:${tag}";
        autoStart = true;
        networks = [ cfg.name ];                  # Isolated app specific network
        volumes = [ "/var/lib/${cfg.name}/cache:/cache:rw" ];
        environment = {
          "NVIDIA_VISIBLE_DEVICES" = "all";       # 
          "NVIDIA_DRIVER_CAPABILITIES" = "all";   # 
        };
        extraOptions = [ ]
          ++ lib.optionals (gpu.nvidia) [
            # Docker allows you to simply pass `--gpus=all`. Podman requires all this
            "--device=/dev/nvidia0"
            "--device=/dev/nvidiactl"
            "--device=/dev/nvidia-modeset"
            "--device=/dev/nvidia-uvm"
            "--device=/dev/nvidia-uvm-tools"
            "--hooks-dir=/etc/containers/oci/hooks.d"
            # Only line needed when using nvidia-container-toolkit
            "--device=nvidia.com/gpu=all"
          ] ++ lib.optionals (gpu.amd) [
            "--device=/dev/video"
            "--device=/dev/dri:/dev/dri"
            "--device=/dev/kfd:/dev/kfd"
          ];
      };

      # Create the "podman-${cfg.name}-redis" service
      virtualisation.oci-containers.containers."${cfg.name}-redis" = {
        hostname = "redis";                       # name server is looking for
        #user = "${toString cfg.user.uid}:${toString cfg.user.gid}";
        image = "docker.io/valkey/valkey:8-bookworm@sha256:fea8b3e67b15729d4bb70589eb03367bab9ad1ee89c876f54327fc7c6e618571";
        autoStart = true;
        networks = [ cfg.name ];                  # Isolated app specific network
      };

      # Create the "podman-${cfg.name}-redis" service
      virtualisation.oci-containers.containers."${cfg.name}-postgres" = {
        hostname = "database";                    # name server is looking for
        #user = "${toString cfg.user.uid}:${toString cfg.user.gid}";
        image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:41eacbe83eca995561fe43814fd4891e16e39632806253848efaf04d3c8a8b84";
        autoStart = true;
        networks = [ cfg.name ];                  # Isolated app specific network
        volumes = [ "/var/lib/${cfg.name}/postgres:/var/lib/postgresql/data:rw" ];
        #user = cfg.user.name;
        environment = {
          "POSTGRES_DB" = "immich";               # Database, "immich" is the suggested value
          "POSTGRES_USER" = "postgres";           # Username, "postgres" is the suggested value
          "DB_STORAGE_TYPE" = "HDD";              # Specify that we are not using SSDs
          "POSTGRES_PASSWORD" = "${cfg.user.pass}"; # Postgres secret e.g. random string only containing `A-Za-z0-9`
          "POSTGRES_INITDB_ARGS" = "--data-checksums";
        };
        extraOptions = [
          "--shm-size=128mb"                      # Increase the shared memory size, default is 64mb
        ];
      };

      # Allow LAN ingress to containers
      networking.firewall.interfaces.${machine.net.bridge.name}.allowedTCPPorts = [ cfg.port ];

      # Extend the services to depend on the podman network
      systemd.services."podman-${cfg.name}-server" = f.extendContService {
        name = cfg.name; deps = [ "redis" "postgres" ]; };
      systemd.services."podman-${cfg.name}-machine-learning" = f.extendContService { name = cfg.name; };
      systemd.services."podman-${cfg.name}-redis" = f.extendContService { name = cfg.name; };
      systemd.services."podman-${cfg.name}-postgres" = f.extendContService { name = cfg.name; };
    })

    # Installs Nvidia Container Toolkit which is a replacement for the older nvidia-docker
    # Essentially it makes the Nvidia GPU available to containers if you then pass in the
    # appropriate --device=/dev/nvidia* and hooks.d to the podman invocation
    (lib.mkIf gpu.nvidia {

      # Getting an error that I can't have both X11 and datacenter enabled at the same time
      #hardware.nvidia.datacenter.enable = true;
      hardware.nvidia-container-toolkit.enable = true;
    })
  ];
}
