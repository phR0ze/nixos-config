# Declares user type for reusability
#---------------------------------------------------------------------------------------------------
{ config, lib, args, ... }:
{
  userType = with lib.types; attrsOf (submodule ({ config, options, ... }: {
    options = {
#      uid = lib.mkOption {
#        description = lib.mdDoc "User id for the user";
#        type = types.int;
#        default = config.users.users.${args.username}.uid;
#      };

      gid = lib.mkOption {
        description = lib.mdDoc "Group id for the user";
        type = types.int;
        default = config.users.groups."users".gid;
      };
    };
  }));
}
