# XPS13 configuration
#
# ### Features
# - Daily driver desktop deployment
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
let
  cfg = config.machine;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../options/types/validate_machine.nix
    (../../profiles/${args.profile}.nix)
  ];

  options = {
    machine = lib.mkOption {
      description = lib.mdDoc "Machine arguments";
      type = types.submodule (import ../../options/types/machine.nix { inherit lib args f; });
    };
  };

  config = {
    machine.type.bootable = true;
    hardware.graphics.intel = true;
    services.xserver.xft.dpi = 115;

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
