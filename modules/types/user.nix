# Declares user options type for reusability
#
# https://nixos.org/manual/nixos/stable/#ex-submodule-direct
#---------------------------------------------------------------------------------------------------
{ lib, defaults }: { config, ... }: with lib.types;
{
  options = {
    name = lib.mkOption {
      description = "User name";
      type = types.nullOr types.str;
      default = defaults.name or null;
    };

    group = lib.mkOption {
      description = "Group name";
      type = types.nullOr types.str;
      default = defaults.name or null;
    };

    pass = lib.mkOption {
      description = "User password to be populated from secrets securely";
      type = types.nullOr types.str;
      default = defaults.pass or null;
    };

    fullname = lib.mkOption {
      description = "User fullname";
      type = types.nullOr types.str;
      default = defaults.fullname or null;
    };

    email = lib.mkOption {
      description = "User email address";
      type = types.nullOr types.str;
      default = defaults.email or null;
    };

    uid = lib.mkOption {
      description = "User id";
      type = types.nullOr types.int;
      default = defaults.uid or null;
    };

    gid = lib.mkOption {
      description = "User group id";
      type = types.nullOr types.int;
    };
  };

  # Group id is always the same as the user id unless explicitly overridden, so setting `uid` alone
  # (e.g. per-machine) is enough to move both consistently
  config = {
    gid = lib.mkDefault config.uid;
  };
}
