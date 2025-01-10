# Declares drive options type for reusability
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
{
  options = {
    uuid = lib.mkOption {
      description = lib.mdDoc "Drive identifier";
      type = types.str;
      default = "";
    };
  };
}
