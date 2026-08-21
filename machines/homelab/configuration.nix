# Homelab configuration
#
# ### Features
# - Homelab server deployment
# --------------------------------------------------------------------------------------------------
{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/xfce/desktop.nix
  ];

  config = {
    machine.type.bootable = true;
    machine.net.bridge.enable = true;
    devices.gpu.nvidia = { enable = true; legacy580 = true; };
    machine.autologin = true;
    system.x11.autolock.enable = true;

    # Apps
    apps.dev.claude.enable = true;

    # System services
    virtualisation.podman.enable = true;
    virtualisation.qemu.host.enable = true;

    # Homelab services
    services.raw.jellyfin.enable = true;
    services.raw.minecraft.enable = true;
    services.raw.nix-cache.host.enable = true;
    services.raw.mullvad.enable = true;
    services.raw.synology-drive-client.enable = true;
    services.raw.vaultwarden = {
      enable = true; port = 8222; subdomain = "vault";
    };
    services.oci.homarr = {
      enable = true; port = 8080; user.uid = 2000; subdomain = "home"; tag = "v1.37.0";
    };
    services.oci.stirling-pdf = {
      enable = true; port = 8081; user.uid = 2001; subdomain = "pdf"; tag = "1.3.2";
    };
    services.oci.oneup = {
      enable = true; port = 8082; user.uid = 2002; subdomain = "oneup"; tag = "latest";
    };
    services.oci.newt = {
      enable = true;
      user.uid = 2005;
      tag = "1.16.0";
      secrets = ./secrets.enc.yaml;
    };

    # HTTPS Proxy service
    services.raw.caddy = {
      enable = true;
      domain = config.machine.domain;
      secrets = ./secrets.enc.yaml;
      proxies = [
        { subdomain = "adguard"; host = config.machine.services.raw.adguard.host; port = 3000; }
        { subdomain = "synology"; host = config.machine.services.raw.synology.host; port = 5000; }
      ];
    };

    # Additional apps
    environment.systemPackages = [
      pkgs.brave
    ];
  };
}
