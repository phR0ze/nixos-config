# vm-test configuration
#
# ### Features
# - Virtual Machine deployment
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
let
  cfg = config.machine;
in
{
  imports = [
    # VM required imports
    ../../options/virtualisation/qemu/guest.nix

    # Profile to follow for machine and standard machine validation
    ../../profiles/xfce/desktop.nix
    ../../options/types/validate_machine.nix
  ];

  options = {
    machine = lib.mkOption {
      type = types.submodule (import ../../options/types/machine.nix { inherit lib args f; });
    };
  };

  config = {
    machine.hostname = "vm-test";
    machine.type.vm = true;
    machine.vm.type.local = true;
    machine.resolution = { x = 1920; y = 1080; };
    machine.autologin = true;

    # VM specification
    # --------------------------------------------
    virtualisation.qemu.guest = {
      cores = 8;
      memorySize = 16;
      rootDrive.size = 40;

      # Full LAN presence with DHCP IP and the given MAC
      interfaces = [{
        type = "macvtap";
        id = cfg.hostname;
        fd = 3;
        macvtap.mode = "bridge";
        macvtap.link = "br0";
        mac = "02:00:00:00:00:01";
      }];
    };

    # Emulate homelab configuration
    # --------------------------------------------
    machine.net.bridge.enable = true;
    machine.nics = [{
      name = "primary";
      id = "eth0";
    }];
#    machine.services = [{
#      name = "stirling-pdf";
#      "nic": {
#        "link": "br0",
#        "ip": "192.168.1.51/24"
#      }
#    }];

#    services.cont.stirling-pdf.enable = true;

    #environment.systemPackages = [
    #  pkgs.x2goclient
    #];
  };
}
