# Theater20 configuration
#
# ### Features
# - Directly installable: xfce/theater with Intel GPU support
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
let
  cfg = config.machine;
  _args = args // (import ./args.nix) // (f.fromYAML ./args.dec.yaml);
in
{
  imports = [
    ./hardware-configuration.nix
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
    programs.hedgewars.enable = true;
    programs.superTuxKart.enable = true;

    environment.systemPackages = [
    ];
  };
}
