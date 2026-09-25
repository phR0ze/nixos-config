# vm-prod1 configuration
#
# ### Features
# - Virtual Machine deployment
# --------------------------------------------------------------------------------------------------
{ config, ... }:
{
  config = {
    host.desktop.xfce.standard = true;
    host.type.vm = true;
    host.autologin = true;
    host.nix.cache.enable = true;

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
    services.immich = {
      enable = true;
      host = "0.0.0.0";       # by default it only listens on localhost
      openFirewall = true;    # allow immich to be reached on the LAN
    };

    # Enable hardware accelerated video transcoding
    users.users.immich.extraGroups = [ "video" "render" ];

    # VM specification
    # --------------------------------------------
    virtualization.qemu.guest = {
      enable = true;
      type.spice = true;
      cores = 4;
      #display = { enable = true; memory = 32; };
      rootDrive.size = 20;
      spice = {
        enable = false;
        port = 5971;
      };
      interfaces = [{
        type = "macvtap";
        fd = 3;
        macvtap.mode = "bridge";
        macvtap.link = "br0";
        mac = "02:00:00:00:00:01";
      }];
    };
  };
}
