# vm-prod1 microvm configuration
# --------------------------------------------------------------------------------------------------
{ inputs, config, pkgs, lib, args, f, ... }: with lib.types;
let
  cfg = config.machine;
  _args = args // (import ./args.nix) // (f.fromYAML ./args.dec.yaml);
in
{
  imports = [
    ../../profiles/xfce/desktop.nix
  ];

  options = {
    machine = lib.mkOption {
      type = types.submodule (import ../../options/types/machine.nix { inherit lib _args f; });
    };
  };

  config = {
    machine.enable = true;
    services.x11vnc.enable = lib.mkForce false;
    microvm.hypervisor = "?";
  };
}
