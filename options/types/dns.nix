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
            example = "1.1.1.1";
            default = "";
          };
          fallback = lib.mkOption {
            description = lib.mdDoc "Fallback DNS IP";
            type = types.str;
            example = "8.8.8.8";
            default = "";
          };
        };
      };
      default = {
        primary = "";
        fallback = ""; 
      };
    };
  };
}
