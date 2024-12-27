# Declares app options type for reusability
#
# For use with docker containers mainly to make it easier to wrap and deploy them
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
let
  nic = import ./nic.nix { inherit lib; };
  user = import ./user.nix { inherit lib; };
in
{
  options = {
    name = lib.mkOption {
      description = lib.mdDoc "App name to use for supporting components";
      type = types.str;
    };

    user = lib.mkOption {
      description = lib.mdDoc "User options for the containerized app";
      type = types.submodule user;
      default = { };
    };

    nic = lib.mkOption {
      description = lib.mdDoc "NIC options for the containerized app";
      type = types.submodule nic;
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
}
