# Homelab configuration
#
# ### Features
# - Homelab server deployment
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  config = {
    host.boot.efi = true;
    host.autologin = true;
    host.desktop.xfce.standard = true;

    system.x11.autolock.enable = true;
    devices.network.bridge.enable = true;
    devices.gpu.nvidia = { enable = true; legacy580 = true; };

    virtualization.podman.enable = true;
    virtualization.qemu.host.enable = true;

    services.native.smb.enable = true;
    services.native.nix-cache.host.enable = true;

    services.native.caddy.enable = true;
    services.native.adguardhome.enable = true;
    services.native.jellyfin.enable = true;

    services.native.minecraft.enable = true;
    services.native.mullvad.enable = true;
    services.native.synology-drive-client.enable = true;
    services.native.vaultwarden = {
      enable = true; port = 8222; subdomains = [ "vault" "vault-vpn" ];
    };
    services.oci.homarr = {
      enable = true; port = 8080; user.uid = 2000; tag = "v1.37.0";
    };
    services.oci.stirling-pdf = {
      enable = true; port = 8081; user.uid = 2001; tag = "1.3.2";
    };
    services.oci.oneup = {
      enable = true; port = 8082; user.uid = 2002; tag = "latest";
    };
    services.oci.newt = {
      enable = true; /*        */ user.uid = 2005; tag = "1.16.0"; 
    };

    # Additional apps
    environment.systemPackages = [
      pkgs.brave
    ];
  };
}
