# Declares service options type for reusability
#
# For use with docker containers mainly to make it easier to wrap and deploy them
#---------------------------------------------------------------------------------------------------
{ lib, defaults, ... }: with lib.types;
{
  options = {
    enable = lib.mkEnableOption "Deploy ${defaults.name or "target"} service";

    name = lib.mkOption {
      description = lib.mdDoc "Service name. Useful for automation";
      type = types.nullOr types.str;
      default = defaults.name or null;
    };

    tag = lib.mkOption {
      description = lib.mdDoc "Service image 'tag' to use";
      type = types.str;
      default = defaults.tag or "latest";
    };

    user = lib.mkOption {
      description = lib.mdDoc "User options for service";
      type = types.nullOr (types.submodule (import ./user.nix { inherit lib; defaults = defaults.user or {}; }));
      default = defaults.user or null;
    };

    port = lib.mkOption {
      description = lib.mdDoc "Service port to use";
      type = types.int;
      default = defaults.port or 80;
    };

    subdomain = lib.mkOption {
      description = lib.mdDoc ''
        Front this service with `services.raw.caddy` at `<subdomain>.<domain>`. Leave `null` to not
        expose it via Caddy.
      '';
      type = types.nullOr types.str;
      default = defaults.subdomain or null;
    };
  };
}
