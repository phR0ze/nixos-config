# Homelab configuration
#
# ### Features
# - Homelab server deployment
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
let
  cfg = config.machine;
in
{
  imports = [
    ./hardware-configuration.nix
    (../../profiles/${args.profile}.nix)
  ];

  config = {
    machine.type.bootable = true;
    machine.net.bridge.enable = true;
    machine.autologin = true;
    services.xserver.autolock.enable = true;

    # Homelab services
    virtualisation.podman.enable = true;
    virtualisation.qemu.host.enable = true;
    services.raw.immich.enable = true;
    services.raw.jellyfin.enable = true;
    services.raw.minecraft.enable = true;
    services.raw.nix-cache.host.enable = true;
    services.raw.private-internet-access.enable = true;
    services.cont.adguard.enable = true;
    services.cont.stirling-pdf.enable = true;
  };
}
