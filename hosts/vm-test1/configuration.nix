# vm-test1 configuration
#
# ### Features
# - For quick isolated testing where more than one node is needed
# --------------------------------------------------------------------------------------------------
{
  host.type.vm = true;
  host.autologin = true;
  host.desktop.xfce = true;

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
        { host = 2222; guest = 22; }
      ];
    }];
  };
}
