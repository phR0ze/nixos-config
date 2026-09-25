# vm-test2 configuration
#
# ### Features
# - For quick isolated testing where more than one node is needed
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  config = {
    host.desktop.xfce.standard = true;

    host.type.vm = true;
    host.autologin = true;
    virtualization.qemu.guest.enable = true;
  };
}
