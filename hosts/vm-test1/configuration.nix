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
    host.vm.type.local = true;
    host.resolution = { x = 1920; y = 1080; };
    host.autologin = true;
    virtualization.qemu.guest.enable = true;
  };
}
