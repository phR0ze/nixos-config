# Vaultwarden
#
# ### Description
# Vaultwarden is an unofficial, lightweight Bitwarden-compatible server implementation written in
# Rust. It's a drop-in replacement for the official Bitwarden server, compatible with all the
# official Bitwarden clients: browser extension, desktop app, mobile app and CLI.
#
# ### Deployment notes
# 1. `domain` defaults to `https://<machine.net.nic0.ip>:<port + 1000>`, matching the HTTPS port
#    `services.raw.caddy` fronts this service on by default. 
# 2. To enable the `/admin` diagnostics page, set `enableAdminPanel = true` and add an admin token to
#    `args.enc.json`:
#    "secrets": [
#       {
#         "name": "vaultwarden-admin",
#         "value": "super-secret-admin-token"
#       }
#     ]
# 3. Point the Bitwarden client(s) at this server's `domain` (or `http://<host>:<port>` on the LAN)
#    and log in as normal — the first account created is a regular user, not an admin.
# 4. Browsers refuse to run the vault's crypto over plain HTTP unless the origin is `localhost` —
#    accessing over `http://<lan-ip>:<port>` fails with a "not a secure context" error. Put this
#    service behind a reverse proxy that terminates TLS (see the homelab reverse-proxy setup).
#
# ### Directories
# - /var/lib/bitwarden_rs
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.services.raw.vaultwarden;
  adminToken = f.getSecret config.machine.secrets "vaultwarden-admin";
in
{
  options = {
    services.raw.vaultwarden = {
      enable = lib.mkEnableOption "Install and configure Vaultwarden server";

      port = lib.mkOption {
        type = types.port;
        default = 8222;
        description = lib.mdDoc "Port the Vaultwarden web/API server listens on.";
      };

      domain = lib.mkOption {
        type = types.nullOr types.str;
        default = "https://${lib.head (lib.splitString "/" config.machine.net.nic0.ip)}:${toString (cfg.port + 1000)}";
        defaultText = lib.literalExpression ''"https://''${machine.net.nic0.ip}:''${port + 1000}"'';
        example = "https://vault.example.com";
        description = lib.mdDoc ''
          Externally reachable URL clients will use to reach this server. Required for WebAuthn/U2F
          and for icons/links to render correctly. Defaults to this host's LAN IP on the Caddy HTTPS
          port (`port + 1000`, matching `services.raw.caddy`'s default `httpsPort`). Set explicitly to
          override.
        '';
      };

      signupsAllowed = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Whether new user signups are allowed.";
      };

      enableAdminPanel = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Whether to enable the `/admin` diagnostics page, protected by an admin token pulled from
          the `vaultwarden-admin` secret in `machine.secrets`.
        '';
      };

      caddy = lib.mkOption {
        description = lib.mdDoc ''
          Front this service with `services.raw.caddy`. Set `enable = true` to add an entry to
          `services.raw.caddy.proxies` automatically.
        '';
        type = types.submodule {
          imports = [ (import ../../../types/caddy_proxy.nix { inherit lib; }) ];
          options.enable = lib.mkEnableOption "Front Vaultwarden with services.raw.caddy";
          config.port = lib.mkDefault cfg.port;
        };
        default = { };
      };

    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

      # Enable Vaultwarden server
      services.vaultwarden = {
        enable = true;
        config = {
          ROCKET_ADDRESS = "0.0.0.0";
          ROCKET_PORT = cfg.port;
          SIGNUPS_ALLOWED = cfg.signupsAllowed;
        } // lib.optionalAttrs (cfg.domain != null) {
          DOMAIN = cfg.domain;
        };
      };

      # TCP: <port>
      networking.firewall.allowedTCPPorts = [ cfg.port ];

      environment.systemPackages = [
        pkgs.vaultwarden      # Vaultwarden server (for the `vaultwarden` CLI tools)
      ];
    })

    # Contribute a proxy entry to services.raw.caddy.proxies rather than requiring it be listed
    # separately in the machine's configuration.nix
    (lib.mkIf (cfg.enable && cfg.caddy.enable) {
      services.raw.caddy.proxies = [
        { inherit (cfg.caddy) subdomain port httpsPort; }
      ];
    })

    # Conditionally enable the admin panel, pulling the token from a generated nix store file
    (lib.mkIf (cfg.enable && cfg.enableAdminPanel) {
      services.vaultwarden.environmentFile = pkgs.runCommandLocal "vaultwarden-admin-token" {} ''
        echo "ADMIN_TOKEN=${adminToken}" > "$out"
      '';
    })
  ];
}
