# Family15 configuration
#
# ### Features
# - Directly installable: xfce/desktop with Intel GPU support
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
    hardware.graphics.intel = true;
    machine.nix.cache.enable = true;
  };
}
