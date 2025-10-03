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
    virtualisation.podman.enable = true;
    users.users.${cfg.user.name} = f.createContUser cfg.user;
    users.groups.${cfg.user.group} = f.createContGroup cfg.user;

    # Add access to hardware acceleration for transcoding
    # - https://wiki.nixos.org/wiki/Immich
    users.users.${cfg.user.name}.extraGroups = [ "video" "render" ];

    # Create persistent directories for application
    systemd.tmpfiles.rules = [
      "d /var/lib/${cfg.name} 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      "d /var/lib/${cfg.name}/data 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
    ];

    # Generate the "podman-${cfg.name}" service unit for the container
    virtualisation.oci-containers.containers."${cfg.name}-server" = {
      image = "ghcr.io/immich-app/${cfg.name}-server:${cfg.tag}";
      autoStart = true;
      hostname = "${cfg.name}";
      ports = [ "${(f.toIP config.net.primary.ip).address}:${toString cfg.port}:80" ];
      volumes = [
        "/var/lib/${cfg.name}/data:/data:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        #"PUID" = "${toString cfg.user.uid}";   # set the user to run as
        #"UPLOAD_LOCATION" = "./library";        # Uploaded files storage location
        "DB_DATA_LOCATION" = "./postgres";      # Database files storage location
        "TZ" = "Etc/UTC";                       # Timezone to use
        # TODO change this
        "DB_PASSWORD" = "postgres"; # Postgres secret e.g. random string only containing `A-Za-z0-9`
        "DB_USERNAME" = "postgres";             # Username, "postgres" is the suggested value
        "DB_DATABASE_NAME" = "immich";          # Database, "immich" is the suggested value
      }; 
      extraOptions = [
        "--network=${cfg.name}"
      ];
    };

    networking.firewall.interfaces.${machine.net.bridge.name}.allowedTCPPorts = [ cfg.port ];

    # Create podmane network and extend service to use it
    systemd.services."podman-network-${cfg.name}" = f.createContNetwork cfg.name;
    systemd.services."podman-${cfg.name}" = f.extendContService cfg.name;
  };

  #systemd.services."podman-network-${cfg.name}" = (import ../../types/service_network.nix { inherit config lib pkgs f cfg; });
}
