# vm-test configuration
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
let
  cfg = config.machine;
  _args = args // (import ./args.nix) // (f.fromYAML ./args.dec.yaml);
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
    machine.enable = true;

    virtualisation.qemu.guest = {
      cores = 1;
      diskSize = 1;
      memorySize = 4;
      sound = true;
      spice = {
        enable = false;
        port = 5970;
      };
      interfaces = [ {
        type = "macvtap";
        id = cfg.hostname;
        fd = 3;
        macvtap.mode = "bridge";
        macvtap.link = "enp1s0";
        mac = "02:00:00:00:00:99";
      }];
    };
  };
}
