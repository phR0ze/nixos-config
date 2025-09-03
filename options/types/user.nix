# Declares user options type for reusability
#
# https://nixos.org/manual/nixos/stable/#ex-submodule-direct
#---------------------------------------------------------------------------------------------------
{ lib, defaults, ... }: with lib.types;
{
  options = {
    name = lib.mkOption {
      description = lib.mdDoc "User name";
      type = types.nullOr types.str;
      default = defaults.name or null;
    };

    group = lib.mkOption {
      description = lib.mdDoc "Group name";
      type = types.nullOr types.str;
      default = defaults.name or null;
    };

    pass = lib.mkOption {
      description = lib.mdDoc "User password to be populated from secrets securely";
      type = types.nullOr types.str;
      default = defaults.pass or null;
    };

    fullname = lib.mkOption {
      description = lib.mdDoc "User fullname";
      type = types.nullOr types.str;
      default = defaults.fullname or null;
    };

    email = lib.mkOption {
      description = lib.mdDoc "User email address";
      type = types.nullOr types.str;
      default = defaults.email or null;
    };

    uid = lib.mkOption {
      description = lib.mdDoc "User id";
      type = types.nullOr types.int;
      default = defaults.uid or null;
    };

    gid = lib.mkOption {
      description = lib.mdDoc "User group id";
      type = types.nullOr types.int;
      default = defaults.gid or null;
    };
  };
}
