# vm-test configuration
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
let
  cfg = config.machine;
in
{
  imports = [
    ../../profiles/base.nix
    #../../profiles/xfce/desktop.nix
    ../../options/virtualisation/qemu/guest.nix
    ../../options/types/validate_machine.nix
  ];

  options = {
    machine = lib.mkOption {
      type = types.submodule (import ../../options/types/machine.nix { inherit lib args f; });
    };
  };

  config = {
    machine.type.vm = true;
    machine.vm.type.micro = true;
    #machine.vm.local = true;
    machine.hostname = "vm-test";
    machine.resolution = { x = 1920; y = 1080; };
    machine.autologin = true;

    #environment.systemPackages = [
    #  pkgs.x2goclient
    #];
  };
}
