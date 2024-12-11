# Declares app options type for reusability
#
# For use with docker containers mainly to make it easier to wrap and deploy them
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
let
  nicOpts = (import ./nic.nix { inherit lib; }).nicOpts;
  userOpts = (import ./user.nix { inherit lib; }).userOpts;
in
{
  appOpts = {
    options = {
      name = lib.mkOption {
        description = lib.mdDoc "App name to use for supporting components";
        type = types.nullOr types.str;
        default = null;
      };

      user = lib.mkOption {
        description = lib.mdDoc "User options for the containerized app";
        type = types.submodule userOpts;
        default = { };
      };

      nic = lib.mkOption {
        description = lib.mdDoc "NIC options for the containerized app";
        type = types.submodule nicOpts;
        default = { };
      };

      configure = lib.mkOption {
        description = lib.mdDoc ''
          Configure the app with preset configuration. This flag can be used to disable any
          preset configuration to boot the app in its default state. Useful for debugging.
        '';
        type = types.bool;
        default = true;
      };
    };
  };
}
