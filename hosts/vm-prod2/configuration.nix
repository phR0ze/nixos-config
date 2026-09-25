# vm-prod2 configuration
#
# ### Features
# - Virtual Machine deployment
# --------------------------------------------------------------------------------------------------
{ config, ... }:
{
  imports = [
  ];

  config = {
    host.desktop.xfce.standard = true;

    host.type.vm = true;
    host.autologin = true;

    # Testing
    # ---------------------------------------------
    #apps.media.obs.enable = true;
    apps.dev.android.enable = true;

    # VM configuration
    # ---------------------------------------------
    virtualization.qemu.guest = {
      enable = true;
      cores = 8;
      memorySize = 16;
      display = {
        enable = true;
        memory = 32;
      };
#      spice = {
#        enable = false;
#        port = 5971;
#      };
      interfaces = [{
        type = "macvtap";
        fd = 3;
        macvtap.mode = "bridge";
        macvtap.link = "br0";
        mac = "02:00:00:00:00:02";
      }];
    };
  };
}
