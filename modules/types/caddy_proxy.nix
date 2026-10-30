# Declares the caddy proxy options type for reusability
#
# Lets an app module declare its own Caddy reverse-proxy config (e.g. `services.native.vaultwarden.caddy`)
# instead of listing it separately under `services.native.caddy.domains.<zone>.proxies` in the machine's
# configuration.nix.
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
{
  options = {
    subdomain = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Subdomain this proxy is reachable at on its zone's hostname-routed wildcard block:
        `<subdomain>.<zone>`. Leave `null` to skip hostname-based routing, in which case this entry
        does nothing.
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
      description = "Backend port on `host` this proxy forwards to.";
    };

    tlsSkipVerify = lib.mkOption {
      type = types.bool;
      default = false;
      description = ''
        Speak HTTPS to the backend without verifying its certificate, for LAN appliances that only
        serve a self-signed one (e.g. Synology DSM on 5001). The hop stays encrypted but isn't
        authenticated, so only use it for backends on a trusted network.
      '';
    };
  };
}
