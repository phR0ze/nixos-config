# vm-prod1 microvm configuration
# --------------------------------------------------------------------------------------------------
{ inputs, config, pkgs, lib, args, f, ... }: with lib.types;
let
  _args = args // (import ./args.nix) // (f.fromYAML ./args.dec.yaml);
in
{
  imports = [
    ../../profiles/microvm.nix
    (../../. + "/profiles" + ("/" + _args.profile + ".nix"))
  ];

  options = {
    machine = lib.mkOption {
      type = types.submodule (import ../../options/types/machine.nix { inherit lib _args f; });
    };
  };

  config = {
      machine.enable = true;
  };
}
