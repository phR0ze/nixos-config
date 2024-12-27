# Declares macvlan options type for reusability
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
{
  options = {
    name = lib.mkOption {
      type = types.str;
      description = lib.mdDoc "MacVLAN name";
    };
    ip = lib.mkOption {
      type = types.str;
      description = lib.mdDoc "MacVLAN IP address";
    };
  };
}
