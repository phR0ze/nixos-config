# Declares DNS as a reusable option
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
{
  options = {
    dns = lib.mkOption {
      description = lib.mdDoc "DNS";
      type = types.submodule {
        options = {
          primary = lib.mkOption {
            description = lib.mdDoc "Primary DNS IP";
            type = types.str;
            default = "1.1.1.1";
          };
          fallback = lib.mkOption {
            description = lib.mdDoc "Fallback DNS IP";
            type = types.str;
            default = "8.8.8.8";
          };
        };
      };
      default = { };
    };
  };
}
