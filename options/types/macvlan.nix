# Declares macvlan options type for reusability
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
{
  options = {
    name = lib.mkOption {
      type = types.nullOr types.str;
      description = lib.mdDoc "MacVLAN name";
      default = null;
    };
    ip = lib.mkOption {
      type = types.nullOr types.str;
      description = lib.mdDoc "MacVLAN IP address";
      default = null;
    };
  };
}
