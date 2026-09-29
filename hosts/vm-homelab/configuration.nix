# VM for testing Homelab configuration
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  config = {
    host.type.vm = true;
    host.autologin = true;
    #host.autolock = true;
    host.desktop.xfce.standard = true;

    virtualization.qemu.guest = {
      cores = 4;
      memorySize = 8;
      rootDrive.size = 40;
      #display.enable = false;
      network.macvtap = true;
    };

    virtualization.podman.enable = true;
    virtualization.qemu.host.enable = true;

    services.native.smb.enable = true;
    services.native.nix-cache.host.enable = true;

    # Caddy fronted services
    services.native.caddy.enable = true;
    services.native.adguardhome.enable = true;
    services.native.jellyfin.enable = true;
    services.oci.oneup = {
      enable = true; port = 8082; user.uid = 2002; tag = "latest";
    };
    services.oci.homarr = {
      enable = true; port = 8080; user.uid = 2000; tag = "v1.37.0";
    };
    services.oci.stirling-pdf = {
      enable = true; port = 8081; user.uid = 2001; tag = "1.3.2";
    };

    # services.native.vaultwarden = {
    #   enable = true; port = 8222; subdomains = [ "vault" "vault-vpn" ];
    # };

    # services.native.mullvad.enable = true;
    #services.native.minecraft.enable = true;
    # services.native.synology-drive-client.enable = true;
    # services.oci.newt = {
    #   enable = true; /*        */ user.uid = 2005; tag = "1.16.0"; 
    # };

    # Additional apps
    environment.systemPackages = [
      pkgs.brave
    ];
  };
}
