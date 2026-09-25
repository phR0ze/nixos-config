# vm-test1 configuration
#
# ### Features
# - For quick isolated testing where more than one node is needed
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ../../layers/bundles/xfce-desktop.nix
  ];

  config = {
    host.type.vm = true;
    machine.resolution = { x = 1920; y = 1080; };
    machine.autologin = true;
    virtualization.qemu.guest.enable = true;
  };
}
