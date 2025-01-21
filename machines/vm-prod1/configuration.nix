# vm-prod1 configuration
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

    virtualisation = {
      cores = 2;
      diskSize = 1 * 1024;
      memorySize = 4 * 1024;
      graphics = false;
      qemu.guest = {
        spice = true;
        spicePort = 5971;
        interfaces = [ {
          type = "macvtap";
          id = cfg.hostname;
          fd = 3;
          macvtap.mode = "bridge";
          macvtap.link = "enp1s0";
          mac = "02:00:00:00:00:01";
        }];
      };
    };
  };
}
