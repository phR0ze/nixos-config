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
  };
}
