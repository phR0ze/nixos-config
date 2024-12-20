# Declares user options type for reusability
#
# https://nixos.org/manual/nixos/stable/#ex-submodule-direct
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
{
  options = {
    name = lib.mkOption {
      description = lib.mdDoc "User name";
      type = types.nullOr types.str;
      default = null;
    };

    uid = lib.mkOption {
      description = lib.mdDoc "User id for the user";
      type = types.nullOr types.int;
      default = null;
    };

    gid = lib.mkOption {
      description = lib.mdDoc "Group id for the user";
      type = types.nullOr types.int;
      default = null;
    };
  };
}
