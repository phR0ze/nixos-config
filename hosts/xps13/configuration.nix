# XPS13 configuration
#
# ### Features
# - Daily driver desktop deployment
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../layers/bundles/xfce-develop.nix
  ];

  config = {
    devices.boot.efi = true;
    devices.gpu.intel.enable = true;
    system.x11.xft.dpi = 115;
    host.smb.secrets = ./secrets.enc.yaml;   # per-share passwords (all default "admin")

    devices.printers.brother-hll2405w = true;

    apps.dev.claude.enable = true;
    apps.dev.gemini.enable = true;
    apps.dev.opencode.enable = true;
    apps.media.obs.enable = true;
    apps.network.rustdesk.autostart = false;

    virtualisation.podman.enable = true;
    virtualization.qemu.host.enable = true;

    environment.systemPackages = [
      pkgs.freetube
      pkgs.rust-analyzer
    ];
  };
}
