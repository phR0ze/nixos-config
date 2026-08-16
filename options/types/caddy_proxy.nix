# Declares the caddy proxy options type for reusability
#
# Lets an app module declare its own Caddy reverse-proxy config (e.g. `services.raw.vaultwarden.caddy`)
# instead of listing it separately under `services.raw.caddy.proxies` in the machine's configuration.nix.
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
{
  options = {
    subdomain = lib.mkOption {
      type = types.str;
      description = lib.mdDoc "Subdomain this proxy is reachable at: `<subdomain>.<domain>`.";
    };

    port = lib.mkOption {
      type = types.port;
      description = lib.mdDoc "Backend HTTP port on localhost this proxy forwards to.";
    };

    httpsPort = lib.mkOption {
      type = types.port;
      default = 443;
      description = lib.mdDoc ''
        HTTPS port Caddy listens on for this proxy. Defaults to 443; override to put this proxy on a
        non-standard port instead.
      '';
    };
  };
}
