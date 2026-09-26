# XPS13 configuration
#
# ### Features
# - Daily driver desktop deployment
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  config = {
    host.desktop.xfce.develop = true;

    host.boot.efi = true;
    devices.gpu.intel.enable = true;
    system.x11.xft.dpi = 115;

    devices.printers.brother-hll2405w = true;

    apps.dev.gemini.enable = true;
    apps.media.obs.enable = true;
    apps.network.rustdesk.autostart = false;

    virtualization.podman.enable = true;
    virtualization.qemu.host.enable = true;

    environment.systemPackages = [
      pkgs.freetube
    ];
  };
}
