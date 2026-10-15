# vm-prod1 configuration
#
# ### Features
# - Virtual Machine deployment
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  config = {
    host.nix.cache.enable = true;
    host.desktop.xfce.standard = true;

    # Test
    # --------------------------------------------
    environment.systemPackages = [
      #pkgs.synology-drive-client
    ];

    # Portainer service
    # --------------------------------------------
    services.oci.portainer.enable = true;
    services.oci.portainer.openFirewall = true; # LAN-reachable via macvtap bridge — deliberate opt-in

    # Immich
    # --------------------------------------------
    services.native.immich = {
      enable = true;
      caddy = false;          # listen on all interfaces with the port opened on the LAN
    };

    # VM specification
    # --------------------------------------------
    host.type.vm = true;
    host.autologin = true;
    virtualization.qemu.guest = {
      type.spice = true;
      cores = 4;
      rootDrive.size = 20;
      spice = {
        enable = false;
        port = 5971;
      };
      network.bridge = true;
    };
  };
}
