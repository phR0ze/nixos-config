# Declares nic options type for reusability
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
{
  options = {
    name = lib.mkOption {
      description = lib.mdDoc "NIC name";
      type = types.str;
      example = "ens18";
      default = "";
    };

    subnet = lib.mkOption {
      description = lib.mdDoc "Network subnet/CIDR";
      type = types.str;
      example = "192.168.1.0/24";
      default = "";
    };

    gateway = lib.mkOption {
      description = lib.mdDoc "Network gateway";
      type = types.str;
      example = "192.168.1.1";
      default = "";
    };

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

    port = lib.mkOption {
      description = lib.mdDoc "Primary port";
      type = types.port;
      example = 80;
    };
  };
}
