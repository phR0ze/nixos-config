# Declares the caddy proxy options type for reusability
#
# Lets an app module declare its own Caddy reverse-proxy config (e.g. `services.native.vaultwarden.caddy`)
# instead of listing it separately under `services.native.caddy.proxies` in the machine's configuration.nix.
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
{
  options = {
    subdomain = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Subdomain this proxy is reachable at on the shared hostname-routed wildcard block:
        `<subdomain>.<domain>`. Leave `null` to skip hostname-based routing, in which case this entry
        does nothing.
      '';
    };

    domains = lib.mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      example = [ "example.com" "example.org" ];
      description = ''
        Zones this proxy is served on, as `<subdomain>.<domain>` for each - each must be
        `services.native.caddy.primaryDomain` or `secondaryDomain`, so reference those options rather
        than literal zones. `null` serves it on `primaryDomain` only.
      '';
    };

    host = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = ''
        Backend host this proxy forwards to. Defaults to `127.0.0.1` for a service running on the
        same host as Caddy; set to another host's LAN IP (or resolvable hostname) to front a service
        running elsewhere on the network.
      '';
    };

    port = lib.mkOption {
      type = types.port;
      description = "Backend HTTP port on `host` this proxy forwards to.";
    };
  };
}
