# Newt configuration
# - https://github.com/fosrl/newt
# - https://docs.pangolin.net/manage/sites/understanding-sites
#
# ### Description
# Newt is Pangolin's site connector — a fully user-space WireGuard tunnel client (netstack-based, no
# host TUN device, no NET_ADMIN) that dials outbound from this homelab to a Pangolin VPS and proxies
# traffic for whatever internal services are exposed as Resources in the Pangolin dashboard. See the
# tech-docs Pangolin doc (`networking/reverse_tunnel/pangolin/README.md`) for the VPS-side setup this
# connects to, and its "Create a Site describing your server" section for where `endpoint`/`id`/secret
# come from.
#
# ### Deployment Details
# - Outbound-only: Newt registers with Pangolin over HTTPS/WebSocket and tunnels over UDP to Gerbil.
#   No inbound ports are published on this host for this service, so no firewall rule is needed either.
# - Fully user-space WireGuard — no Linux capabilities, no `/dev/net/tun`, so the container runs
#   `--cap-drop=ALL`, non-root, and (by default) with a read-only rootfs.
# - `endpoint`/`id` are pulled from `args.services.oci.newt` (`args.enc.json`) the same way Homarr's
#   `encKey` is — identify *which* site connects, but grant nothing without the secret below.
# - The Newt client secret is the actual site-connector credential, so it's kept out of the Nix store
#   entirely via sops-nix rather than args.enc.json. Point `secrets` at a `secrets.enc.yaml` holding a
#   `newt.clientSecret` key from the machine's `configuration.nix`:
#     services.oci.newt = {
#       enable = true;
#       tag = "<pin a version — see github.com/fosrl/newt/releases>";
#       secrets = ./secrets.enc.yaml;
#     };
# - Get the Endpoint/ID/Secret from the Pangolin dashboard: `Network > Sites > + Add Site > Newt Site
#   (Recommended)`, then use the `Endpoint`/`ID`/`Secret` values shown under `Install Site > Docker`
#   rather than the generated `docker run` string.
# - Get status with: sudo systemctl status podman-newt
# --------------------------------------------------------------------------------------------------
{ config, lib, args, pkgs, f, ... }: with lib.types;
let
  cfg = config.services.oci.newt;

  defaults = f.getService args "newt";
in
{
  imports = [ (import ../../types/service_base.nix { inherit config lib pkgs f cfg; }) ];

  options = {
    services.oci.newt = lib.mkOption {
      description = lib.mdDoc "Newt (Pangolin site connector) service options";
      type = types.submodule {
        options = {
          endpoint = lib.mkOption {
            description = lib.mdDoc "Pangolin server base URL this site connects to";
            type = types.str;
            default = args.services.oci.newt.endpoint or "";
            example = "https://pangolin.example.com";
          };

          id = lib.mkOption {
            description = lib.mdDoc "Newt Site ID issued by Pangolin when the Site is created";
            type = types.str;
            default = args.services.oci.newt.id or "";
          };

          secrets = lib.mkOption {
            type = types.path;
            example = "./secrets.enc.yaml";
            description = lib.mdDoc ''
              Path to the sops-encrypted file holding the `newt.clientSecret` secret — the Newt
              Site's Secret from the Pangolin dashboard. Declared here so
              `sops.secrets."newt/clientSecret"` doesn't need to be repeated in every machine's
              `configuration.nix`.
            '';
          };

          logLevel = lib.mkOption {
            type = types.enum [ "DEBUG" "INFO" "WARN" "ERROR" ];
            default = "INFO";
            description = lib.mdDoc "Newt log verbosity.";
          };

          readOnlyRootfs = lib.mkOption {
            type = types.bool;
            default = true;
            description = lib.mdDoc ''
              Run the container with a read-only root filesystem plus a small writable `/tmp` tmpfs.
              Newt is stateless and persists nothing, so this stays on by default — turn off only if
              a future Newt release starts writing somewhere else at runtime and fails to start.
            '';
          };
        };
        imports = [ (import ../../types/service.nix { inherit lib defaults; }) ];
      };
      default = defaults;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = cfg.endpoint != "";
        message = "services.oci.newt requires 'endpoint' set (args.services.oci.newt.endpoint) — the Pangolin dashboard's base URL"; }
      { assertion = cfg.id != "";
        message = "services.oci.newt requires 'id' set (args.services.oci.newt.id) — from the Pangolin Site's Newt credentials"; }
    ];

    virtualisation.podman.enable = true;
    users.users.${cfg.user.name} = f.createUser cfg.user;
    users.groups.${cfg.user.group} = f.createGroup cfg.user;

    # Decrypted to /run/secrets/newt/clientSecret at activation — never touches the Nix store
    sops.secrets."newt/clientSecret" = {
      sopsFile = cfg.secrets;
    };

    # Combine the sensitive secret with the non-secret endpoint/id into one env file for the
    # container, so NEWT_SECRET never lands in `podman inspect`/process listing the way a plain
    # `environment` entry would
    sops.templates."newt.env".content = ''
      PANGOLIN_ENDPOINT=${cfg.endpoint}
      NEWT_ID=${cfg.id}
      NEWT_SECRET=${config.sops.placeholder."newt/clientSecret"}
      LOG_LEVEL=${cfg.logLevel}
    '';

    # Generate the "podman-newt" service unit for the container
    # - cfg.port is unused here (Newt publishes no ports) — kept only because it's part of the
    #   shared service.nix type this module reuses for name/tag/user consistency
    virtualisation.oci-containers.containers."${cfg.name}" = {
      image = "docker.io/fosrl/newt:${cfg.tag}";
      autoStart = true;
      hostname = "${cfg.name}";
      user = "${toString cfg.user.uid}:${toString cfg.user.gid}";
      networks = [ cfg.name ];                  # Isolated app specific network
      environment = {
        # CONFIG_FILE is Newt's documented override (see resolveConfigFilePath in fosrl/newt) —
        # point it at the writable /tmp tmpfs mounted below instead.
        CONFIG_FILE = "/tmp/newt-client/config.json";
      };
      environmentFiles = [ config.sops.templates."newt.env".path ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
      ];
      extraOptions = [
        "--cap-drop=ALL"                        # Fully user-space WireGuard — no NET_ADMIN/tun needed
        "--security-opt=no-new-privileges"
      ] ++ lib.optionals cfg.readOnlyRootfs [
        "--read-only"
        "--tmpfs=/tmp"
      ];
    };

    # Newt is outbound-only (dials out to Pangolin/Gerbil) — nothing to publish, so no
    # networking.firewall rule is added for it, unlike the other services.oci.* modules

    # Create podman network and extend service to use it
    systemd.services."podman-network-${cfg.name}" = f.createContNetwork cfg.name;
    systemd.services."podman-${cfg.name}" = f.extendContService { name = cfg.name; };
  };
}
