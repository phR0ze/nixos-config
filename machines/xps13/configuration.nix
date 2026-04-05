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
    devices.gpu.intel.enable = true;
    system.x11.xft.dpi = 115;

    devices.printers.brother-hll2405w = true;

    apps.dev.claude.enable = true;
    apps.dev.gemini.enable = true;
    apps.dev.opencode.enable = true;
    apps.media.obs.enable = true;
    apps.network.rustdesk.autostart = false;

    virtualisation.podman.enable = true;
    virtualisation.qemu.host.enable = true;

    environment.systemPackages = [
      pkgs.freetube
      pkgs.rust-analyzer
    ];
  };
}
