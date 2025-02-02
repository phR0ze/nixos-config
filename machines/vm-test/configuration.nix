# vm-test configuration
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
let
  cfg = config.machine;
  _args = args // (f.fromYAML ./args.dec.yaml);
in
{
  imports = [
    ../../options/virtualisation/qemu/guest.nix
    (../../. + "/profiles" + ("/" + _args.profile + ".nix"))
  ];

  options = {
    machine = lib.mkOption {
      type = types.submodule (import ../../options/types/machine.nix { inherit lib _args f; });
    };
  };

  config = {
    machine.vm.micro = true;
    machine.hostname = "vm-test";
    machine.profile = "xfce/desktop";
    machine.resolution = { x = 1920; y = 1080; };
    machine.autologin = true;
    machine.nic0.name = "eth0";
  };
}
