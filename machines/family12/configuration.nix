# Family12 configuration
#
# ### Features
# - Directly installable: xfce/develop with Intel GPU support
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

    # AMD is not the right selection need older Radeon
    #hardware.graphics.amd = true;

    # Having some weird issue with firewall failing
    networking.firewall.enable = false;

    environment.systemPackages = [

    ];
  };
}
