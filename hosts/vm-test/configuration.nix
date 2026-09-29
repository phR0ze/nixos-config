# vm-test configuration
# --------------------------------------------------------------------------------------------------
{
  config = {
    host.type.vm = true;
    host.autologin = true;
    host.desktop.xfce.theater = true;

    virtualization.qemu.guest = {
      cores = 4;
      memorySize = 8;
      rootDrive.size = 40;
      #display.enable = false;
      network.macvtap = true;
      # network.forwardPorts = [
      #   { host = 2222; guest = 22; }
      #   { host = 8080; guest = 80; }
      #   { host = 8443; guest = 443; }
      #   { host = 9000; guest = 9000; }
      # ];
    };
  };
}
