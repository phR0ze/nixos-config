# Declares IP as a reusable option
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
{
  options = {
    ip = lib.mkOption {
      description = lib.mdDoc "NIC IP";
      type = types.submodule {
        options = {
          full = lib.mkOption {
            description = lib.mdDoc "Full IP and CIDR combination";
            type = types.str;
            default = "";
            example = "192.168.1.41/24";
          };
          attrs = lib.mkOption {
            description = lib.mdDoc "Attribute set version of the IP";
            type = types.attrs;
            default = { };
            example = {
              address = "192.168.1.41";
              prefixLength = 24;
            };
          };
        };
      };
      default = {};
    };
  };
}
