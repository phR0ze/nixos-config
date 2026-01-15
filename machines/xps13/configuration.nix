# XPS13 configuration
#
# ### Features
# - Daily driver desktop deployment
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/xfce/develop.nix
  ];

  config = {
    machine.type.bootable = true;
    devices.gpu.intel = true;
    system.x11.xft.dpi = 115;

    #machine.net.bridge.enable = true;
    virtualisation.podman.enable = true;
    #virtualisation.qemu.host.enable = true;
    services.raw.rustdesk.autostart = false;
    apps.media.obs.enable = true;

    # Misc
    environment.systemPackages = [
      pkgs.freetube
    ];
  };
}
