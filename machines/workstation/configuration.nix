# Workstation configuration
#
# ### Features
# - Directly installable: generic/develop with AMD GPU support
# - barrier server configuration
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
let
  cfg = config.machine;
  _args = lib.recursiveUpdate args (lib.recursiveUpdate (import ./args.nix) (f.fromJSON ./args.dec.json));
in
{
  imports = [
    ./hardware-configuration.nix
    ../../options/types/validate_machine.nix
    (../../. + "/profiles" + ("/" + _args.profile + ".nix"))
  ];

  options = {
    machine = lib.mkOption {
      description = lib.mdDoc "Machine arguments";
      type = types.submodule (import ../../options/types/machine.nix { inherit lib _args f; });
    };
  };

  config = {
    machine.enable = true;

    # Hardware
    hardware.graphics.amd = true;

    # Services
    services.barriers.enable = true;

    # Utilities
    programs.freecad.enable = true;
    virtualisation.podman.enable = true;
    virtualisation.qemu.host.enable = true;

    # Games
    programs.hedgewars.enable = true;
    programs.superTuxKart.enable = true;

    # Multimedia
    programs.xnviewmp.enable = true;

    # Misc
    environment.systemPackages = [
      pkgs.freetube
      pkgs.wiiload
      pkgs.wiimms-iso-tools
      pkgs.gamecube-tools
      pkgs.quickemu
    ];
  };
}
