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
      description = lib.mdDoc "App name";
      type = types.str;
    };

    user = lib.mkOption {
      description = lib.mdDoc "User options for app";
      type = types.submodule user;
      default = { };
    };

    nic = lib.mkOption {
      description = lib.mdDoc "NIC options for app";
      type = types.submodule nic;
      default = { };
    };

    port = lib.mkOption {
      description = lib.mdDoc "App port to use";
      type = types.int;
      default = 80;
    };
  };
}
