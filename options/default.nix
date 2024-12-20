# Import all the options
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
let
  opts = import ./types { inherit lib; };
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
      description = lib.mdDoc "Type of deployment";
      type = types.submodule opts.type;
      default = { };
    };

    user = lib.mkOption {
      description = lib.mdDoc "User options for the containerized app";
      type = types.submodule opts.user;
      default = { };
    };
  };
}
