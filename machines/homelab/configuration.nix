# Homelab configuration
#
# ### Features
# - Homelab server deployment
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/xfce/desktop.nix
  ];

  config = {
    machine.type.bootable = true;
    machine.net.bridge.enable = true;
    devices.gpu.nvidia = true;
    machine.autologin = true;
    system.x11.autolock.enable = true;

    # Configure remoting
    #services.raw.sunshine.enable = true;
    #services.raw.rustdesk.enable = false;

    # Homelab services
    virtualisation.podman.enable = true;
    virtualisation.qemu.host.enable = true;
    services.raw.jellyfin.enable = true;
    services.raw.minecraft.enable = true;
    services.raw.nix-cache.host.enable = true;
    services.raw.adguardhome.enable = true;
    services.raw.mullvad.enable = true;
    services.raw.synology-drive-client.enable = true;
    services.oci.homarr = { enable = true; port = 80; };
    services.oci.oneup = { enable = true; port = 8002; };
    services.oci.stirling-pdf = { enable = true; port = 8001; };
    services.oci.immich = { enable = true; port = 2283; tag = "v2.0.1"; };

    environment.systemPackages = [
      pkgs.brave
    ];
  };
}
