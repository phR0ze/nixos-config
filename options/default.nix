# Import all the options
#---------------------------------------------------------------------------------------------------
{ lib, ... }:
let
  types = import ./types { inherit lib; };
in
{
  imports = [
    ./desktop
    ./development
    ./files
    ./games
    ./hardware
    ./homelab
    ./office
    ./multimedia
    ./network
    ./services
    ./utils
    ./virtualization
  ];

  options.deployment = {
    type = lib.mkOption {
      description = lib.mdDoc "Deployment type";
      type = lib.types.submodule types.deployment;
      default = { };
    };

    user = lib.mkOption {
      description = lib.mdDoc "User options";
      type = lib.types.submodule types.user;
      default = { };
    };
  };
}
