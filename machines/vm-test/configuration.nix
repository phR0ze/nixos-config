# Test VM configuration
#
# --------------------------------------------------------------------------------------------------
{ modulesPath, config, pkgs, lib, args, f, ... }: with lib.types;
let
  cfg = config.machine;
  _args = args // (import ./args.nix) // (f.fromYAML ./args.dec.yaml);
in
{
  imports = [
    (modulesPath + "/virtualisation/qemu-vm.nix")
    (../../. + "/profiles" + ("/" + _args.profile + ".nix"))
  ];

  options = {
    machine = lib.mkOption {
      description = lib.mdDoc "Machine arguments";
      type = types.submodule (import ../../options/types/machine.nix { inherit lib _args f; });
    };
  };

  config = lib.mkMerge [
    {
      machine.enable = true;

      # [Macvtap](https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking#macvtap)
      virtualization.qemu.guest.interfaces = [ {
        type = "macvtap";
        id = cfg.hostname;
        fd = 3;
        macvtap.mode = "bridge";
        macvtap.link = cfg.macvtap.host;
        mac = "02:00:00:00:00:01";
      }];
    }
  ];
}
