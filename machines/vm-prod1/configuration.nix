# vm-prod1 configuration
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
let
  cfg = config.machine;
  _args = args // (f.fromYAML ./args.dec.yaml);
in
{
  imports = [
    ../../profiles/xfce/desktop.nix
    ../../options/virtualisation/qemu/guest.nix
  ];

  options = {
    machine = lib.mkOption {
      type = types.submodule (import ../../options/types/machine.nix { inherit lib _args f; });
    };
  };

  config = {
    machine.type.vm = true;
    machine.vm.local = true;
    machine.hostname = "vm-prod1";
    machine.resolution = { x = 1920; y = 1080; };
    machine.autologin = true;

    #services.x2goserver.enable = true;
    #environment.systemPackages = [
    #  pkgs.x2goserver
    #];

#    virtualisation.qemu.guest = {
#      cores = 4;
#      display = {
#        enable = true;
#        memory = 32;
#      };
#      spice = {
#        enable = false;
#        port = 5971;
#      };
#      interfaces = [{
#        type = "user";
#        id = cfg.hostname;
#        fd = 3;
#        macvtap.mode = "bridge";
#        macvtap.link = "enp1s0";
#        mac = "02:00:00:00:00:01";
#      }];
#    };
  };
}
