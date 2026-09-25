# Homelab configuration
#
# ### Features
# - Homelab server deployment
# --------------------------------------------------------------------------------------------------
{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  config = {
    devices.boot.efi = true;
    devices.network.bridge.enable = true;
    devices.gpu.nvidia = { enable = true; legacy580 = true; };
    host.desktop.xfce.standard = true;
    host.autologin = true;
    system.x11.autolock.enable = true;

    # Apps
    apps.dev.claude.enable = true;

    # System services
    virtualisation.podman.enable = true;
    virtualization.qemu.host.enable = true;

    # Homelab services
    services.raw.minecraft.enable = true;
    services.native.nix-cache.host.enable = true;
    services.raw.mullvad.enable = true;
    services.native.synology-drive-client.enable = true;
    services.native.jellyfin = {
      enable = true; port = 8096; subdomain = "jellyfin";
    };
    services.native.vaultwarden = {
      enable = true; port = 8222; subdomains = [ "vault" "vault-vpn" ];
    };
    services.oci.homarr = {
      enable = true; port = 8080; user.uid = 2000; subdomain = "home"; tag = "v1.37.0";
      secrets = ./secrets.enc.yaml;
    };
    services.oci.stirling-pdf = {
      enable = true; port = 8081; user.uid = 2001; subdomain = "pdf"; tag = "1.3.2";
    };
    services.oci.oneup = {
      enable = true; port = 8082; user.uid = 2002; subdomain = "oneup"; tag = "latest";
    };
    services.oci.newt = {
      enable = true; /*        */ user.uid = 2005; secrets = ./secrets.enc.yaml; tag = "1.16.0"; 
    };

    # HTTPS Proxy service
    # - `baseDomain`, `sopsFile` and the off-machine `proxies` entries (the remote AdGuard/Synology LAN
    #   IPs) are all forwarded by modules/default.nix from this host's args/secrets, see
    #   `host.services.native.caddy.proxies` in args.enc.yaml
    services.native.caddy.enable = true;

    # Additional apps
    environment.systemPackages = [
      pkgs.brave
    ];
  };
}
