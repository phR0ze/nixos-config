# vm-test configuration
#
# ### Features
# - Virtual Machine deployment
# --------------------------------------------------------------------------------------------------
{
  config = {
    host.desktop.xfce.theater = true;
    host.type.vm = true;
    host.autologin = true;

    virtualization.qemu.guest = {
      enable = true;
      cores = 4;
      memorySize = 8;
      rootDrive.size = 40;
      network.forwardPorts = [
        { host = 2222; guest = 22; }
        { host = 8080; guest = 80; }
        { host = 8443; guest = 443; }
        { host = 9000; guest = 9000; }
      ];
    };

#    # Testing packages
#    # --------------------------------------------
#    #apps.games.prismlauncher.enable = true;
#
#    # Emulate homelab configuration for services development
#    # --------------------------------------------
#    devices.network.bridge.enable = true;
#    devices.network.macvlan = {
#      name = "host";
#      ip = "192.168.1.61/24";
#    };
#    devices.network.nic0 = {
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
