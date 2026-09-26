# vm-test1 configuration
#
# ### Features
# - For quick isolated testing where more than one node is needed
# --------------------------------------------------------------------------------------------------
{
  host.desktop.xfce.standard = true;

  host.type.vm = true;
  host.autologin = true;

  virtualization.qemu.guest = {
    enable = true;
    cores = 4;
    memorySize = 8;
    rootDrive.size = 40;
  };
}
