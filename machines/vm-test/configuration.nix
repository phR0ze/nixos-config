# vm-test configuration
#
# ### Features
# - Virtual Machine deployment
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ../../options/virtualisation/qemu/guest.nix
    ../../profiles/xfce/desktop.nix
    #../../profiles/budgie/base.nix
  ];

  config = {
    machine.hostname = "vm-test";
    machine.type.vm = true;
    machine.vm.type.local = true;
    machine.resolution = { x = 1920; y = 1080; };
    machine.autologin = true;

    apps.dev.claude.enable = true;
    services.oci.portainer.enable = true;

    # Beefed up VM specs with DHCP full LAN presence
    # --------------------------------------------
    virtualisation.qemu.guest = {
      cores = 4;
      memorySize = 8;
      rootDrive.size = 40;
      display.enable = false;
      interfaces = [{
        type = "user";
        id = "vm-test";
        forwardPorts = [
          { host = 8080; guest = 80; }
          { host = 8443; guest = 443; }
          { host = 9000; guest = 9000; }
        ];
      }];
#      interfaces = [{
#        type = "macvtap";
#        id = cfg.hostname;
#        fd = 3;
#        macvtap.mode = "bridge";
#        macvtap.link = "br0";
#        mac = "02:00:00:00:00:01";
#      }];
    };
#
#    # Testing packages
#    # --------------------------------------------
#    #apps.games.prismlauncher.enable = true;
#
#    # Emulate homelab configuration for services development
#    # --------------------------------------------
#    machine.net.bridge.enable = true;
#    machine.net.macvlan = {
#      name = "host";
#      ip = "192.168.1.61/24";
#    };
#    machine.net.nic0 = {
#      name = "eth0";
#      ip = "192.168.1.60/24";
#    };
#    services.oci.homarr = {
#      enable = true;
#      port = 8080;
#    };
#    services.oci.stirling-pdf = {
#      enable = true;
#      port = 8081;
#    };
#    services.oci.oneup = {
#      enable = true;
#      port = 8082;
#    };
#    services.oci.immich = {
#      enable = true;
#      port = 2283;
#      tag = "v2.0.1";
#    };

#    environment.systemPackages = [
#      pkgs.kasmweb
#    ];
  };
}
