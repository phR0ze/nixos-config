# VM for testing Homelab configuration
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  config = {
    # VM specification
    host.type.vm = true;
    virtualization.qemu.guest = {
      cores = 4;
      memorySize = 8;
      rootDrive.size = 40;
      #display.enable = false;
      network.macvtap = true;
    };

    # Server specification
    host.autologin = true;
    #host.autolock = true;
    host.desktop.xfce.standard = true;
    host.backupDir = "/mnt/Apps/vm-homelab";

    virtualization.podman.enable = true;
    virtualization.qemu.host.enable = true;

    services.native.smb.enable = true;
    services.native.mullvad.enable = true;
    services.native.minecraft.enable = true;
    services.native.nix-cache.host.enable = true;
    services.oci.newt = {
      enable = true; user.uid = 2005; tag = "1.16.0"; 
    };

    # Caddy fronted services
    services.native.caddy.enable = true;
    services.native.adguardhome.enable = true;
    services.native.jellyfin.enable = true;
    services.oci.homarr = {
      enable = true; port = 8080; user.uid = 2000; tag = "v1.37.0";
    };
    services.oci.stirling-pdf = {
      enable = true; port = 8081; user.uid = 2001; tag = "1.3.2";
    };
    services.oci.oneup = {
      enable = true; port = 8082; user.uid = 2002; tag = "latest";
    };
    services.native.vaultwarden = {
      enable = true; port = 8222; subdomains = [ "vault" "vault-vpn" ];
    };

    # Additional apps
    environment.systemPackages = [
      pkgs.brave
    ];
  };
}
