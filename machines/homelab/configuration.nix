# Homelab configuration
#
# ### Features
# - Directly installable: 
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
    machine.autologin = true;
    services.xserver.autolock.enable = true;

    services.raw.jellyfin.enable = true;
    services.raw.nix-cache.host.enable = true;
    #services.nspawn.portainer.enable = true;
    #services.nspawn.stirling-pdf.enable = true;
  };
}
