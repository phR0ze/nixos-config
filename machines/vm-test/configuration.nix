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
    ../../options/virtualisation/qemu/guest.nix
    #../../profiles/base.nix
    ../../profiles/xfce/desktop.nix
  ];

  config = {
    machine.hostname = "vm-test";
    machine.type.vm = true;
    machine.vm.type.local = true;
    #machine.vm.type.local = false;
    machine.resolution = { x = 1920; y = 1080; };
    machine.autologin = true;

    # Beefed up VM specs with DHCP full LAN presence
    # --------------------------------------------
    virtualisation.qemu.guest = {
      cores = 8;
      memorySize = 16;
      rootDrive.size = 40;
      interfaces = [{
        type = "macvtap";
        id = cfg.hostname;
        fd = 3;
        macvtap.mode = "bridge";
        macvtap.link = "br0";
        mac = "02:00:00:00:00:01";
      }];
    };

    # DNS local service testing
    # --------------------------------------------
    machine.net.dns.primary = "192.168.1.53";
    machine.net.dns.fallback = "192.168.1.53";

    # Emulate homelab configuration for services development
    # --------------------------------------------
    machine.net.bridge.enable = true;
    machine.nics = [{
      name = "primary";
      id = "eth0";
    }];
    services.cont.oneup = {
      enable = true;
      nic.ip = "192.168.1.52/24";
    };

#    services.cont.stirling-pdf = {
#      enable = true;
#      nic.ip = "192.168.1.51/24";
#    };
#    services.cont.adguard = {
#      enable = true;
#      nic.ip = "192.168.1.52/24";
#    };

    #environment.systemPackages = [
    #  pkgs.x2goclient
    #];
  };
}
