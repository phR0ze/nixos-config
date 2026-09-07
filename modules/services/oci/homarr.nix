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
  cfg = config.services.oci.homarr;

  defaults = f.getService args "homarr";
in
{
  imports = [ (import ../../types/service_base.nix { inherit config lib pkgs f cfg; }) ];

  options = {
    services.oci.homarr = lib.mkOption {
      description = lib.mdDoc "Homarr service options";
      type = types.submodule {
        options = {
          encKey = lib.mkOption {
            description = lib.mdDoc ''
              Encryption key used to encrypt secrets in database. Only used as a fallback when
              `secrets` is unset -- prefer `secrets` (sops-encrypted, decrypted only at
              activation) over this (baked into the Nix store via args.enc.yaml).
            '';
            type = types.str;
            example = "Create with `open ssl rand -hex 32`";
            default = args.services.oci.homarr.encKey or "";
          };

          secrets = lib.mkOption {
            description = lib.mdDoc ''
              Path to the sops-encrypted file holding the `homarr/encKey` secret. When set, takes
              precedence over the plaintext `encKey` fallback above.
            '';
            type = types.nullOr types.path;
            default = null;
            example = "./secrets.enc.yaml";
          };
        };
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
        "d /var/lib/${cfg.name}/appdata 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      ];

      # Decrypted at activation to sops-nix's default path (config.secret.templates."homarr-<name>".path,
      # normally /run/secrets/rendered/homarr-<name>), never touching the Nix store
      secret.templates = lib.mkIf (cfg.secrets != null) {
        "homarr-${cfg.name}" = {
          filemode = "0400";
          content = ''
            SECRET_ENCRYPTION_KEY=${config.secret.ref."homarr/encKey"}
          '';
          secrets."homarr/encKey".sopsFile = cfg.secrets;
        };
      };

      # Generate the "podman-${cfg.name}" service unit for the container
      virtualisation.oci-containers.containers."${cfg.name}" = {
        # Direct non-root is not supported
        #user = "${toString cfg.user.uid}:${toString cfg.user.gid}";
        image = "ghcr.io/homarr-labs/homarr:${cfg.tag}";
        autoStart = true;
        hostname = "${cfg.name}";
        networks = [ cfg.name ];                  # Isolated app specific network
        ports = [ "127.0.0.1:${toString cfg.port}:7575" ];  # Not exposed on LAN; front with services.raw.caddy
        volumes = [
          "/var/lib/${cfg.name}/appdata:/appdata:rw"
        ];
        extraOptions = [ "--ip=${cfg.ip}" ];

        # Configure app via overrides
        environment = {
          "PUID" = "${toString cfg.user.uid}";    # Change to non-root
          "PGID" = "${toString cfg.user.gid}";    # Change to non-root
        } // lib.optionalAttrs (cfg.secrets == null) { "SECRET_ENCRYPTION_KEY" = cfg.encKey; };
        environmentFiles = lib.optionals (cfg.secrets != null) [ config.secret.templates."homarr-${cfg.name}".path ];
      };

      # Create podmane network and extend service to use it
      systemd.services."podman-network-${cfg.name}" = f.createContNetwork { name = cfg.name; subnet = cfg.subnet; };
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

