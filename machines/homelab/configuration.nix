# Homelab configuration
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
let
  cfg = config.machine;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../options/types/validate_machine.nix
    (../../. + "/profiles" + ("/" + args.profile + ".nix"))
  ];

  options = {
    machine = lib.mkOption {
      description = lib.mdDoc "Machine arguments";
      type = types.submodule (import ../../options/types/machine.nix { inherit lib args f; });
    };
  };

  config = {
    machine.type.bootable = true;
    machine.net.bridge.enable = true;

    services.cache.host = true;
    services.x11vnc.enable = lib.mkForce false;

    services.nspawn.portainer.enable = true;
    services.nspawn.stirling-pdf.enable = true;
  };
}
