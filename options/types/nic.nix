# Declares nic options type for reusability
#---------------------------------------------------------------------------------------------------
{ lib, defaults, ... }: with lib.types;
{
  options = {
    name = lib.mkOption {
      description = lib.mdDoc "Descriptive NIC name used as a well known tag";
      type = types.str;
      example = "primary";
      default = defaults.name or ""; 
    };

    id = lib.mkOption {
      description = lib.mdDoc "NIC identifier in the system";
      type = types.str;
      example = "ens18";
      default = defaults.id or "";
    };

    link = lib.mkOption {
      description = lib.mdDoc ''
        NIC link name. Useful for containers and VMs when creating a macvlan on the host bridge 
        e.g.'br0' which would be the link name in this case";
      '';
      type = types.str;
      example = "br0";
      default = defaults.link or "";
    };

    subnet = lib.mkOption {
      description = lib.mdDoc "Network subnet/CIDR";
      type = types.str;
      example = "192.168.1.0/24";
      default = defaults.subnet or "";
    };

    gateway = lib.mkOption {
      description = lib.mdDoc "Network gateway";
      type = types.str;
      example = "192.168.1.1";
      default = defaults.gateway or "";
    };

    ip = lib.mkOption {
      description = lib.mdDoc "IP and CIDR combination";
      type = types.str;
      example = "192.168.1.41/24";
      default = defaults.ip or "";
    };

    dns = lib.mkOption {
      description = lib.mdDoc "DNS";
      type = types.nullOr (types.submodule {
        options = {
          primary = lib.mkOption {
            description = lib.mdDoc "Primary DNS IP";
            type = types.str;
            example = "1.1.1.1";
            default = "1.1.1.1";
          };
          fallback = lib.mkOption {
            description = lib.mdDoc "Fallback DNS IP";
            type = types.str;
            example = "8.8.8.8";
            default = "8.8.8.8";
          };
        };
      });
      default = defaults.dns or {
        primary = "1.1.1.1";
        fallback = "8.8.8.8";
      };
    };
  };
}
