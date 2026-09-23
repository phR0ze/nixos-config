# vm-test configuration
#
# ### Features
# - Virtual Machine deployment
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ../../layers/bundles/xfce-desktop.nix
  ];

  config = {
    host.type.vm = true;
    host.vm.type.local = true;
    host.resolution = { x = 1920; y = 1080; };
    host.autologin = true;
    #host.net.dns.force = true;

    # Beefed up VM specs with DHCP full LAN presence
    # --------------------------------------------
    virtualization.qemu.guest = {
      enable = true;
      cores = 4;
      memorySize = 8;
      rootDrive.size = 40;
      display.enable = true;
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
#    host.net.bridge.enable = true;
#    host.net.macvlan = {
#      name = "host";
#      ip = "192.168.1.61/24";
#    };
#    host.net.nic0 = {
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
