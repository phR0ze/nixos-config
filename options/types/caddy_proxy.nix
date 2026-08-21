# Declares the caddy proxy options type for reusability
#
# Lets an app module declare its own Caddy reverse-proxy config (e.g. `services.raw.vaultwarden.caddy`)
# instead of listing it separately under `services.raw.caddy.proxies` in the machine's configuration.nix.
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
{
  options = {
    subdomain = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = lib.mdDoc ''
        Subdomain this proxy is reachable at on the shared hostname-routed wildcard block:
        `<subdomain>.<domain>`. Leave `null` to skip hostname-based routing, in which case this entry
        does nothing.
      '';
    };

    host = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = lib.mdDoc ''
        Backend host this proxy forwards to. Defaults to `127.0.0.1` for a service running on the
        same host as Caddy; set to another host's LAN IP (or resolvable hostname) to front a service
        running elsewhere on the network.
      '';
    };

    port = lib.mkOption {
      type = types.port;
      description = lib.mdDoc "Backend HTTP port on `host` this proxy forwards to.";
    };
  };
}
