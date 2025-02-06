# Family15 configuration
#
# ### Features
# - Directly installable: xfce/desktop with Intel GPU support
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
let
  cfg = config.machine;
  _args = lib.recursiveUpdate args (lib.recursiveUpdate (import ./args.nix) (f.fromJSON ./args.dec.json));
in
{
  imports = [
    ./hardware-configuration.nix
    ../../options/types/validate_machine.nix
    (../../. + "/profiles" + ("/" + _args.profile + ".nix"))
  ];

  options = {
    machine = lib.mkOption {
      description = lib.mdDoc "Machine arguments";
      type = types.submodule (import ../../options/types/machine.nix { inherit lib _args f; });
    };
  };

  config = {
    machine.enable = true;
    hardware.graphics.intel = true;

    environment.systemPackages = [
    ];
  };
}
