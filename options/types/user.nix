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

    pass = lib.mkOption {
      description = lib.mdDoc "User password to be populated from secrets securely";
      type = types.nullOr types.str;
      default = null;
    };

    fullname = lib.mkOption {
      description = lib.mdDoc "User fullname";
      type = types.nullOr types.str;
      default = null;
    };

    email = lib.mkOption {
      description = lib.mdDoc "User email address";
      type = types.nullOr types.str;
      default = null;
    };

    uid = lib.mkOption {
      description = lib.mdDoc "User id";
      type = types.nullOr types.int;
      default = null;
    };

    gid = lib.mkOption {
      description = lib.mdDoc "User group id";
      type = types.nullOr types.int;
      default = null;
    };
  };
}
