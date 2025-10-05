# Homarr configuration
# - https://github.com/homarr-labs/homarr
# - https://homarr.dev/docs/getting-started/installation/docker
#
# ### Description
# A modern and easy to use dashboard. 30+ integrations. 10K+ icons built in. Authentication out of 
# the box. No YAML, drag and drop configuration
#
# 🖌️ Highly customizable with an extensive drag and drop grid system
# ✨ Integrates seamlessly with your favorite self-hosted applications
# 📌 Easy and fast app management - no YAML involved
# 👤 Detailed and easy to use user management with permissions and groups
#
# ### Deployment Details
# - App data is persisted at /var/lib/$APP
# - Generate key with: openssl rand -hex 32
# - Get status with: sudo systemctl status podman-homarr
# - Browse to: http://<IP>:8080
# --------------------------------------------------------------------------------------------------
{ config, lib, args, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.services.oci.homarr;

  defaults = f.getService args "homarr" 2000 2000;
in
{
  imports = [ (import ../../types/service_base.nix { inherit config lib pkgs f cfg; }) ];

  options = {
    services.oci.homarr = lib.mkOption {
      description = lib.mdDoc "Homarr service options";
      type = types.submodule {
        options = {
          encKey = lib.mkOption {
            description = lib.mdDoc "Encryption key used to encrypt secrets in database";
            type = types.str;
            example = "Create with `open ssl rand -hex 32`";
            default = args.services.oci.homarr.encKey or "";
          };
        };
        imports = [ (import ../../types/service.nix { inherit lib defaults; }) ];
      };
      default = defaults;
    };
  };
 
  config = lib.mkIf cfg.enable {
    virtualisation.podman.enable = true;
    users.users.${cfg.user.name} = f.createContUser cfg.user;
    users.groups.${cfg.user.group} = f.createContGroup cfg.user;

    networking.firewall.interfaces.${machine.net.bridge.name}.allowedTCPPorts = [ cfg.port ];

    # Create persistent directories for application
    # - Args: type, path, mode, user, group, expiration
    # - No group specified, i.e `-` defaults to root
    # - No age specified, i.e `-` defaults to infinite
    systemd.tmpfiles.rules = [
      "d /var/lib/${cfg.name}/appdata 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
    ];

    # Generate the "podman-${cfg.name}" service unit for the container
    virtualisation.oci-containers.containers."${cfg.name}" = {
      # Direct non-root is not supported
      #user = "${toString cfg.user.uid}:${toString cfg.user.gid}";
      image = "ghcr.io/homarr-labs/homarr:${cfg.tag}";
      autoStart = true;
      hostname = "${cfg.name}";
      ports = [ "${(f.toIP config.net.primary.ip).address}:${toString cfg.port}:7575" ];
      volumes = [
        "/var/lib/${cfg.name}/appdata:/appdata:rw"
      ];

      # Configure app via overrides
      environment = {
        "PUID" = "${toString cfg.user.uid}";    # Change to non-root
        "PGID" = "${toString cfg.user.gid}";    # Change to non-root
        "SECRET_ENCRYPTION_KEY" = cfg.encKey;
      };
      extraOptions = [
        "--network=${cfg.name}"
      ];
    };

    # Create podmane network and extend service to use it
    systemd.services."podman-network-${cfg.name}" = f.createContNetwork cfg.name;
    systemd.services."podman-${cfg.name}" = f.extendContService { name = cfg.name; };
  };
}
