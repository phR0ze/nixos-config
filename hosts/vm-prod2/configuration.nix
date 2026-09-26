# vm-prod2 configuration
#
# ### Features
# - Virtual Machine deployment
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
  ];

  config = {
    host.desktop.xfce.standard = true;

    # Testing
    # ---------------------------------------------
    #apps.media.obs.enable = true;
    apps.dev.android.enable = true;

    # VM configuration
    # ---------------------------------------------
    host.type.vm = true;
    host.autologin = true;
    virtualization.qemu.guest = {
      enable = true;
      cores = 8;
      memorySize = 16;
      network.bridge = true;
    };
  };
}
