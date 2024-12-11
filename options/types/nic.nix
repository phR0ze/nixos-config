# Declares nic options type for reusability
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
{
  nicOpts = {
    options = {
      name = lib.mkOption {
        description = lib.mdDoc "NIC name";
        type = types.nullOr types.str;
        default = null;
        example = "ens18";
      };

      subnet = lib.mkOption {
        description = lib.mdDoc "Network subnet/CIDR";
        type = types.nullOr types.str;
        default = null;
        example = "192.168.1.0/24";
      };

      gateway = lib.mkOption {
        description = lib.mdDoc "Network gateway";
        type = types.nullOr types.str;
        default = null;
        example = "192.168.1.1";
      };

      ip = lib.mkOption {
        description = lib.mdDoc "Primary IP address";
        type = types.nullOr types.str;
        default = null;
        example = "192.168.1.41";
      };

      ip2 = lib.mkOption {
        description = lib.mdDoc "Secondary IP address";
        type = types.nullOr types.str;
        default = null;
        example = "192.168.1.42";
      };

      port = lib.mkOption {
        description = lib.mdDoc "Primary port";
        type = types.nullOr types.port;
        default = null;
        example = 80;
      };
    };
  };
}
