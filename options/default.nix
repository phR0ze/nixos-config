# Import all the options
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }: with lib.types;
let
  #machine = config.machine;
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

  options = {
    machine = lib.mkOption {
      description = lib.mdDoc "Machine external arguments";
      type = types.submodule (import ./types/machine.nix { inherit lib; });
      default = { };
    };
  };

  # Validate flake user args are set
#  config = {
#    assertions = [
#      { assertion = (machine.user.name != ""); message = "machine.user.name needs to be set"; }
#      { assertion = (machine.comment != ""); message = "machine.comment needs to be set"; }
#
#      # Networking args
#      { assertion = (machine.hostname != ""); message = "machine.hostname needs to be set"; }
#      { assertion = (machine.nic0.name != ""); message = "machine.nic0.name needs to be set"; }
#    ];
#  };
}
