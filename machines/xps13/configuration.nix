# XPS13 configuration
#
# ### Features
# - Daily driver desktop deployment
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
{
  imports = [
    ./hardware-configuration.nix
    (../../profiles/${args.profile}.nix)
  ];

  config = {
    machine.type.bootable = true;
    hardware.graphics.intel = true;
    system.x11.xft.dpi = 115;

    #machine.net.bridge.enable = true;
    virtualisation.podman.enable = true;
    #virtualisation.qemu.host.enable = true;
    services.raw.rustdesk.autostart = false;
    apps.media.obs.enable = true;

    # Misc
    environment.systemPackages = [
      pkgs.freetube
    ];
  };
}
