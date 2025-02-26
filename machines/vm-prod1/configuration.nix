# vm-prod1 configuration
#
# ### Features
# - Virtual Machine deployment
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
let
  cfg = config.machine;
in
{
  imports = [
    ../../profiles/xfce/desktop.nix
    ../../options/virtualisation/qemu/guest.nix
    ../../options/types/validate_machine.nix
  ];

  options = {
    machine = lib.mkOption {
      type = types.submodule (import ../../options/types/machine.nix { inherit lib args f; });
    };
  };

  config = {
    machine.type.vm = true;
    machine.vm.type.local = true;
    machine.resolution = { x = 1920; y = 1080; };
    machine.autologin = true;
    machine.nix.cache.enable = true;

    # Test
    # --------------------------------------------
    environment.systemPackages = [
      #pkgs.synology-drive-client
    ];

    #assertions = [
    #  { assertion = (cfg.smb.enable == false); message = "machin.smb.enable: ${f.boolToStr cfg.smb.enable}"; }
    #];

    # Portainer service
    # --------------------------------------------
    services.cont.portainer.enable = true;

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
      display = { enable = true; memory = 32; };
      rootDrive.size = 20;
#      spice = {
#        enable = false;
#        port = 5971;
#      };
      interfaces = [{
        type = "macvtap";
        id = cfg.hostname;
        fd = 3;
        macvtap.mode = "bridge";
        macvtap.link = "br0";
        mac = "02:00:00:00:00:01";
      }];
    };
  };
}
