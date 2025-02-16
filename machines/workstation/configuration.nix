# Workstation configuration
#
# ### Features
# - Directly installable: generic/develop with AMD GPU support
# - barrier server configuration
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
let
  cfg = config.machine;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../options/types/validate_machine.nix
    (../../profiles + ("/" + args.profile + ".nix"))
  ];

  options = {
    machine = lib.mkOption {
      description = lib.mdDoc "Machine arguments";
      type = types.submodule (import ../../options/types/machine.nix { inherit lib args f; });
    };
  };

  config = {
    machine.type.bootable = true;
    hardware.graphics.amd = true;
    machine.net.bridge.enable = true;

    services.raw.barriers.enable = true;
    services.raw.rustdesk.autostart = false;

    virtualisation.podman.enable = true;
    virtualisation.qemu.host.enable = true;

    apps.games.hedgewars.enable = true;
    apps.games.superTuxKart.enable = true;
    apps.media.freecad.enable = true;
    apps.media.xnviewmp.enable = true;

    # Misc
    environment.systemPackages = [
      pkgs.synology-drive-client
      pkgs.freetube
      pkgs.wiiload
      pkgs.wiimms-iso-tools
      pkgs.gamecube-tools
      pkgs.quickemu
    ];
  };
}
