# Declares user options type for reusability
#
# https://nixos.org/manual/nixos/stable/#ex-submodule-direct
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
{
  options = {
    name = lib.mkOption {
      description = lib.mdDoc "User name";
      type = types.str;
    };

    pass = lib.mkOption {
      description = lib.mdDoc "User password to be populated from secrets securely";
      type = types.str;
    };

    fullname = lib.mkOption {
      description = lib.mdDoc "User fullname";
      type = types.str;
    };

    email = lib.mkOption {
      description = lib.mdDoc "User email address";
      type = types.str;
    };

    uid = lib.mkOption {
      description = lib.mdDoc "User id";
      type = types.int;
    };

    gid = lib.mkOption {
      description = lib.mdDoc "User group id";
      type = types.int;
    };
  };
}
