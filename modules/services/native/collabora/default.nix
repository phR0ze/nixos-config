# Collabora Online
#
# ### Description
# Collabora Online (CODE) edits office documents in the browser, on LibreOffice's core. Nextcloud
# Office (`richdocuments`) embeds it, see `services.native.nextcloud.office`, which enables this
# module and fills in `wopiHosts`.
#
# ### Deployment notes
# 1. Wraps upstream `services.collabora-online`, listening on `127.0.0.1:<port>` only and served
#    through Caddy's TLS at `<subdomain>.<zone>` for each `subdomains` entry. There's no plain-LAN
#    mode, as the editor is embedded in an HTTPS page and can't be loaded over HTTP.
# 2. The browser loads the editor from `hostName`, the one public name Collabora reports in its
#    discovery. Nextcloud reaches it over loopback, and it calls back to Nextcloud through local
#    Caddy, so both sides stay inside this host.
# 3. Pangolin: VPN and LAN only, as the editor runs in an iframe that can't pass Pangolin's SSO.
#    Add a private-only Newt resource keyed like the subdomain, so the Pangolin client resolves the
#    same name, e.g. `office: { public: false, private: true }`. On the LAN, `hostName` must resolve
#    to this host, e.g. through AdGuard Home's rewrites.
# 4. Hardened beyond upstream's defaults:
#    - Only `wopiHosts` may open documents, and only loopback may use the REST API (`convert-to`,
#      used by Nextcloud for previews). Caddy proxies from loopback too, so anyone who can reach
#      `hostName` can convert files, which is why it's kept off the internet.
#    - No egress besides localhost, so no update checks, Zotero or other remote services.
#    - The admin console is off, documents are monitored through `journalctl -u coolwsd`.
# 5. Stateless: documents live in Nextcloud and `/var/lib/cool` is regenerated, so no backups.
# --------------------------------------------------------------------------------------------------
{ config, lib, f, ... }: with lib.types;
let
  cfg = config.services.native.collabora;

  # Regex for an exact host, as Collabora matches aliases and `post_allow` as regexes
  escape = lib.escapeRegex;
in
{
  options = {
    # `domains`/`whichDomains`: which Caddy zones it's served on, see modules/types/caddy_domains.nix
    services.native.collabora = (import ../../../types/caddy_domains.nix { inherit lib; }) // {
      enable = lib.mkEnableOption "Install and configure Collabora Online";

      port = lib.mkOption {
        type = types.port;
        default = 9980;
        description = "Port coolwsd listens on, on loopback.";
      };

      subdomains = lib.mkOption {
        type = listOf types.str;
        default = [ "office" ];
        description = "Subdomains Caddy serves it on. The first, on the primary zone, is `hostName`.";
      };

      hostName = lib.mkOption {
        type = types.nullOr types.str;
        default = if cfg.domains == [ ] || cfg.subdomains == [ ] then null
          else "${lib.head cfg.subdomains}.${lib.head cfg.domains}";
        defaultText = lib.literalExpression ''"''${lib.head subdomains}.''${lib.head domains}"'';
        example = "office.example.com";
        description = "Public name the browser loads the editor from, see deployment note 2.";
      };

      wopiHosts = lib.mkOption {
        type = listOf types.str;
        default = [ ];
        example = [ "nextcloud.example.com" ];
        description = ''
          Hostnames of the WOPI hosts, e.g. Nextcloud, allowed to open documents, over HTTPS. Set
          by `services.native.nextcloud.office`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = cfg.hostName != null;
        message = "services.native.collabora requires 'hostName', the default needs 'domains' and 'subdomains'"; }
      { assertion = cfg.wopiHosts != [ ];
        message = "services.native.collabora requires 'wopiHosts', e.g. by enabling services.native.nextcloud.office"; }
      (f.caddyDomainsAssert "native.collabora" cfg)
    ];

    services.collabora-online = {
      enable = true;
      inherit (cfg) port;
      # Every WOPI host as one group, the first being the canonical name
      aliasGroups = [ {
        host = "https://${lib.head cfg.wopiHosts}:443";
        aliases = map (h: "https://${escape h}:443") (lib.tail cfg.wopiHosts);
      } ];
      settings = {
        server_name = cfg.hostName;
        # TLS is terminated by Caddy
        ssl = { enable = false; termination = true; };
        # IPv4 only, as `loopback` with `all` may bind [::1] alone
        net = {
          listen = "loopback";
          proto = "IPv4";
          post_allow.host = [ (escape "127.0.0.1") (escape "::ffff:127.0.0.1") (escape "::1") ];
        };
        storage.wopi.alias_groups."@mode" = "groups";
        admin_console.enable = false;
        fetch_update_check = 0;
        allow_update_popup = false;
        zotero.enable = false;
        logging.color = false;
      };
    };

    # See deployment note 4. The WOPI hosts resolve to local Caddy, see services.native.nextcloud
    systemd.services.coolwsd.serviceConfig = {
      IPAddressDeny = "any";
      IPAddressAllow = [ "localhost" ];
    };

    services.native.caddy.enable = lib.mkDefault true;
    services.native.caddy.domains = f.caddyProxies cfg (map (sub: { subdomain = sub; inherit (cfg) port; }) cfg.subdomains);
  };
}
