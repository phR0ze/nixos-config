# Declares DNS as a reusable option
#---------------------------------------------------------------------------------------------------
{ lib, defaults, ... }: with lib.types;
{
  options = {
    primary = lib.mkOption {
      description = lib.mdDoc "Primary DNS IP";
      type = types.nullOr types.str;
      example = "1.1.1.1";
      default = defaults.primary or null;
    };

    fallback = lib.mkOption {
      description = lib.mdDoc "Fallback DNS IP";
      type = types.nullOr types.str;
      example = "8.8.8.8";
      default = defaults.fallback or null;
    };

    force = lib.mkOption {
      description = lib.mdDoc ''
        Force all DNS queries through `primary`/`fallback`, ignoring whatever DNS any link is
        separately handed (e.g. via DHCP). Off by default so DHCP-provided per-link DNS can still
        win, which lets NetworkManager detect and handle captive portals (airline wifi, hotels,
        etc.) using the portal network's own DNS. Only enable this on machines that don't need
        captive portal support, e.g. VMs with a static upstream like `vm-test`.
      '';
      type = types.bool;
      default = defaults.force or false;
    };
  };
}
