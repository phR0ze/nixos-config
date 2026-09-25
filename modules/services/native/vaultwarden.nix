# Vaultwarden
#
# ### Description
# Vaultwarden is an unofficial, lightweight Bitwarden-compatible server implementation written in
# Rust. It's a drop-in replacement for the official Bitwarden server, compatible with all the
# official Bitwarden clients: browser extension, desktop app, mobile app and CLI.
#
# ### Deployment notes
# 1. Vaultwarden listens on `127.0.0.1:<port>` only (not exposed on the LAN).
# 2. `domain` defaults to `https://<first subdomains entry>.<baseDomain>`, where `baseDomain` is
#    forwarded from `host.network.domain` by `modules/default.nix`. Set `domain` explicitly to
#    override.
# 3. To enable the `/admin` diagnostics page, set `enableAdminPanel = true` and add an admin token to
#    this host's `secrets.enc.yaml` under the `vaultwarden/adminToken` key. `sopsFile` is forwarded
#    from `host.sopsFile` by `modules/default.nix`, so nothing else is needed in the host's
#    `configuration.nix`.
# 4. Point the Bitwarden client(s) at this server's `domain` and log in as normal — the first
#    account created is a regular user, not an admin.
# 5. To reach this service through a Pangolin *private* (ZTNA) resource instead of a public
#    subdomain, use a `Host`-mode (raw L4 tunnel) resource pointed straight at this host's LAN
#    `IP:443` — the same shared wildcard block `subdomains` above already uses. Pangolin never
#    terminates or re-originates TLS for that resource type, so the client's real SNI/Host header
#    reaches Caddy intact, same as any LAN client; no dedicated listener or port is needed. Add a
#    second entry to `subdomains` if you want the private resource to have its own distinct name
#    rather than reusing the first one — Caddy routes every entry identically.
#
# ### Directories
# - /var/lib/vaultwarden
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.native.vaultwarden;
in
{
  options = {
    services.native.vaultwarden = {
      enable = lib.mkEnableOption "Install and configure Vaultwarden server";

      port = lib.mkOption {
        type = types.port;
        default = 8222;
        description = lib.mdDoc "Port the Vaultwarden web/API server listens on.";
      };

      baseDomain = lib.mkOption {
        type = types.str;
        default = "";
        example = "example.com";
        description = lib.mdDoc ''
          Zone this server is reachable under, used to build `domain`'s default. Forwarded from
          `host.network.domain` by `modules/default.nix` so the literal zone never lands in a
          tracked file - only set here to override. Empty by default so that forwarding can be
          unconditional - see the `enable`-gated assertion below.
        '';
      };

      domain = lib.mkOption {
        type = types.nullOr types.str;
        default = if cfg.baseDomain == "" then null
          else "https://${builtins.head cfg.subdomains}.${cfg.baseDomain}";
        defaultText = lib.literalExpression ''"https://''${builtins.head subdomains}.''${baseDomain}"'';
        example = "https://vault.example.com";
        description = lib.mdDoc ''
          Externally reachable URL clients will use to reach this server. Required for WebAuthn/U2F
          and for icons/links to render correctly. Defaults to `https://<first subdomains
          entry>.<baseDomain>`. Set explicitly to override.
        '';
      };

      sopsFile = lib.mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "./secrets.enc.yaml";
        description = lib.mdDoc ''
          Path to the sops-encrypted file holding the `vaultwarden/adminToken` secret, forwarded
          from `host.sopsFile` by `modules/default.nix`. Only required when `enableAdminPanel` is
          set - see that block's assertion below.
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
          `secret.files."vaultwarden/adminToken"`.
        '';
      };

      subdomains = lib.mkOption {
        description = lib.mdDoc ''
          Front this service with `services.native.caddy` at `<subdomain>.<domain>` for each entry
          listed — every one gets its own hostname matcher on Caddy's shared wildcard block, all
          routed to the same backend. The first entry is also what `domain` defaults to. List more
          than one to give this service multiple names (e.g. a distinct name for a Pangolin private
          resource — see deployment note 5 above); Caddy treats every entry identically.
        '';
        type = listOf types.str;
        example = [ "vault" "vault-vpn" ];
      };

    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        { assertion = cfg.baseDomain != "" || cfg.domain != null;
          message = "services.native.vaultwarden requires 'baseDomain', normally forwarded from 'host.network.domain', or an explicit 'domain'"; }
      ];

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

      # Contribute a proxy entry per subdomain to services.native.caddy.proxies rather than
      # requiring them be listed separately in the host's configuration.nix
      services.native.caddy.proxies = map (s: { subdomain = s; inherit (cfg) port; }) cfg.subdomains;
    }

    # Conditionally enable the admin panel, pulling the token from the sops-nix secret rather than
    # baking it into the nix store
    (lib.mkIf cfg.enableAdminPanel {
      assertions = [
        { assertion = cfg.sopsFile != null;
          message = "services.native.vaultwarden with enableAdminPanel requires 'sopsFile', normally forwarded from 'host.sopsFile'"; }
      ];

      secret.templates."vaultwarden-admin" = {
        filemode = "0400";
        content = ''
          ADMIN_TOKEN=${config.secret.ref."vaultwarden/adminToken"}
        '';
        secrets."vaultwarden/adminToken".sopsFile = cfg.sopsFile;
        # EnvironmentFile is only read at unit start, so a rotated admin token needs a restart
        restartUnits = [ "vaultwarden.service" ];
      };

      services.vaultwarden.environmentFile = config.secret.templates."vaultwarden-admin".path;
    })
  ]);
}
