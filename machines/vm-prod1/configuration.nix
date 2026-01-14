# vm-prod1 configuration
#
# ### Features
# - Virtual Machine deployment
# --------------------------------------------------------------------------------------------------
{ config, ... }:
{
  imports = [
    ../../profiles/xfce/desktop.nix
    ../../options/virtualisation/qemu/guest.nix
  ];

  config = {
    machine.type.vm = true;
    machine.vm.type.spice = true;
    machine.resolution = { x = 1920; y = 1080; };
    machine.autologin = true;
    machine.nix.cache.enable = true;

    # Test
    # --------------------------------------------
    environment.systemPackages = [
      #pkgs.synology-drive-client
    ];

    # Portainer service
    # --------------------------------------------
    services.oci.portainer.enable = true;

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
    virtualisation.qemu.guest = {
      cores = 4;
      #display = { enable = true; memory = 32; };
      rootDrive.size = 20;
      spice = {
        enable = false;
        port = 5971;
      };
      interfaces = [{
        type = "macvtap";
        id = config.hostname;
        fd = 3;
        macvtap.mode = "bridge";
        macvtap.link = "br0";
        mac = "02:00:00:00:00:01";
      }];
    };
  };
}
