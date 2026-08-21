# Vaultwarden
#
# ### Description
# Vaultwarden is an unofficial, lightweight Bitwarden-compatible server implementation written in
# Rust. It's a drop-in replacement for the official Bitwarden server, compatible with all the
# official Bitwarden clients: browser extension, desktop app, mobile app and CLI.
#
# ### Deployment notes
# 1. Vaultwarden listens on `127.0.0.1:<port>` only (not exposed on the LAN). `subdomain` is required
#    and fronts this service with `services.raw.caddy`'s Let's Encrypt-backed TLS termination —
#    browsers refuse to run the vault's crypto over plain HTTP unless the origin is `localhost`, so a
#    Caddy-terminated HTTPS subdomain is the supported way to reach this service.
# 2. `domain` defaults to `https://<subdomain>.<machine.domain>`. Set explicitly to override.
# 3. To enable the `/admin` diagnostics page, set `enableAdminPanel = true` and add an admin token to
#    a `secrets.enc.yaml` under the `vaultwarden.adminToken` key, then declare it in the machine's
#    `configuration.nix` (this module only consumes the secret, it doesn't declare it, since
#    `sopsFile` is a path relative to wherever it's declared):
#      sops.secrets."vaultwarden/adminToken" = {
#        sopsFile = ./secrets.enc.yaml;
#      };
# 4. Point the Bitwarden client(s) at this server's `domain` and log in as normal — the first
#    account created is a regular user, not an admin.
# 5. To reach this service through a Pangolin *private* (ZTNA) resource instead of the public
#    `subdomain`, use a `Host`-mode (raw L4 tunnel) resource pointed straight at this machine's LAN
#    `IP:443` — the same shared wildcard block `subdomain` above already uses. Pangolin never
#    terminates or re-originates TLS for that resource type, so the client's real SNI/Host header
#    reaches Caddy intact, same as any LAN client; no dedicated listener or port is needed.
#
# ### Directories
# - /var/lib/bitwarden_rs
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.raw.vaultwarden;
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
        default = "https://${cfg.subdomain}.${config.machine.domain}";
        defaultText = lib.literalExpression ''"https://''${subdomain}.''${machine.domain}"'';
        example = "https://vault.example.com";
        description = lib.mdDoc ''
          Externally reachable URL clients will use to reach this server. Required for WebAuthn/U2F
          and for icons/links to render correctly. Defaults to `https://<subdomain>.<machine.domain>`.
          Set explicitly to override.
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
          `sops.secrets."vaultwarden/adminToken"`.
        '';
      };

      subdomain = lib.mkOption {
        description = lib.mdDoc ''
          Front this service with `services.raw.caddy` at `<subdomain>.<domain>`.
        '';
        type = types.str;
        example = "vault";
      };

    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

      # Enable Vaultwarden server
      services.vaultwarden = {
        enable = true;
        config = {
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = cfg.port;
          SIGNUPS_ALLOWED = cfg.signupsAllowed;
        } // lib.optionalAttrs (cfg.domain != null) {
          DOMAIN = cfg.domain;
        };
      };

      environment.systemPackages = [
        pkgs.vaultwarden      # Vaultwarden server (for the `vaultwarden` CLI tools)
      ];
    })

    # Contribute a proxy entry to services.raw.caddy.proxies rather than requiring it be listed
    # separately in the machine's configuration.nix
    (lib.mkIf cfg.enable {
      services.raw.caddy.proxies = [
        { inherit (cfg) subdomain port; }
      ];
    })

    # Conditionally enable the admin panel, pulling the token from the sops-nix secret rather than
    # baking it into the nix store
    (lib.mkIf (cfg.enable && cfg.enableAdminPanel) {
      assertions = [
        { assertion = config.sops.secrets ? "vaultwarden/adminToken"; message = "services.raw.vaultwarden with enableAdminPanel requires sops.secrets.\"vaultwarden/adminToken\" to be declared"; }
      ];

      sops.templates."vaultwarden-admin.env".content = ''
        ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/adminToken"}
      '';

      services.vaultwarden.environmentFile = config.sops.templates."vaultwarden-admin.env".path;
    })
  ];
}
