# Declares the options choosing which Caddy zones an app is served on
#
# Merged into the options of every Caddy-fronted app (`modules/types/service.nix` for the OCI ones,
# `//`-merged by hand into the native ones). The app then registers its proxies on those zones with
# `services.native.caddy.domains = f.caddyProxies cfg [ { ... } ];`.
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
{
  domains = lib.mkOption {
    description = ''
      Zones this host owns, the first being the primary. Forwarded from `host.network.domains` by
      `modules/default.nix` so the literal zones stay out of tracked files.
    '';
    type = types.listOf types.str;
    default = [ ];
  };

  whichDomains = lib.mkOption {
    description = ''
      Which of `domains` Caddy serves this app on: `primary` (the first) or `all`. Serving it on
      every zone lets a Pangolin server under any of them reach it by the same name.
    '';
    type = types.enum [ "primary" "all" ];
    default = "primary";
  };
}
