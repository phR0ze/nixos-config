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
    host.autolock = true;
    host.autologin = true;
    host.desktop.xfce.standard = true;
    devices.gpu.nvidia = { enable = true; open = true; };    # GeForce GTX 1660 (Turing)

    virtualization.podman.enable = true;
    virtualization.qemu.host.enable = true;

    services.native.smb.enable = true;
    services.native.mullvad.enable = true;
    services.native.minecraft.enable = true;
    services.native.nix-cache.host.enable = true;
    services.oci.newt = {
      enable = true; user.uid = 2005; tag = "1.18.1";
    };

    # Caddy fronted services
    services.native.caddy.enable = true;
    services.native.adguardhome.enable = true;
    services.native.jellyfin.enable = true;
    services.oci.homarr = {
      enable = true; port = 8080; user.uid = 2000; tag = "v2.3.0";
    };
    services.oci.stirling-pdf = {
      enable = true; port = 8081; user.uid = 2001; tag = "3.1.0";
    };
    services.oci.oneup = {
      enable = true; port = 8082; user.uid = 2002; tag = "latest";
    };
    services.native.vaultwarden = {
      enable = true; port = 8222; subdomains = [ "vault" "vault-vpn" ];
    };
    # services.native.immich = {
    #   enable = false; port = 2283; subdomains = [ "immich" "immich-vpn" ]; cuda = true;
    # };

    # Additional apps
    environment.systemPackages = [
      pkgs.brave
    ];
  };
}
