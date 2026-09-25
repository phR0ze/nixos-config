# vm-test2 configuration
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
    host.autologin = true;
    virtualization.qemu.guest.enable = true;
  };
}
