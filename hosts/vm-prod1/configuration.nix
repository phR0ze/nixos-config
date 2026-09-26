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
    services.immich = {
      enable = true;
      host = "0.0.0.0";       # by default it only listens on localhost
      openFirewall = true;    # allow immich to be reached on the LAN
    };

    # Enable hardware accelerated video transcoding
    users.users.immich.extraGroups = [ "video" "render" ];

    # VM specification
    # --------------------------------------------
    host.type.vm = true;
    host.autologin = true;
    virtualization.qemu.guest = {
      enable = true;
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
