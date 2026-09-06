# Declares user options type for reusability
#
# https://nixos.org/manual/nixos/stable/#ex-submodule-direct
#---------------------------------------------------------------------------------------------------
{ lib, defaults }: { config, ... }: with lib.types;
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
    };

    secret = lib.mkEnableOption ''
      Source this account's username, primary group, and password entirely from host.secrets at
      activation time via nixos-files' users.fromSecret, instead of from name/pass above. Keeps
      the account's real identity out of the Nix store and out of git entirely (not even
      encrypted-at-rest) - only an internal placeholder name is ever evaluated. See
      modules/system/users.nix
    '';
  };

  # Group id is always the same as the user id unless explicitly overridden, so setting `uid` alone
  # (e.g. per-machine) is enough to move both consistently
  config = {
    gid = lib.mkDefault config.uid;
  };
}
