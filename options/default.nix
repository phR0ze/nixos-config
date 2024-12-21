# Import all the options
#---------------------------------------------------------------------------------------------------
{ lib, args, ... }:
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
  };

  # Validate flake user args are set
  config = {
    assertions = [
      { assertion = (args.username != ""); message = "args.username needs to be set"; }
      { assertion = (args.comment != ""); message = "args.comment needs to be set"; }

      # Networking args
      { assertion = (args.hostname != ""); message = "args.hostname needs to be set"; }
      { assertion = (args.nic0 != ""); message = "args.nic0 needs to be set"; }
    ];
  };
}
