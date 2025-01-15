# Workstation configuration
#
# ### Features
# - Directly installable: generic/develop with AMD GPU support
# - barrier server configuration
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
let
  cfg = config.machine;
  _args = args // (import ./args.nix) // (f.fromYAML ./args.dec.yaml);
in
{
  imports = [
    ../../profiles/xfce/develop.nix
    ./hardware-configuration.nix
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
    virtualization.podman.enable = true;
    virtualization.virt-manager.enable = true;

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
