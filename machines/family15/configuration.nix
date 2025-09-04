# Family15 configuration
#
# ### Features
# - Basic desktop deployment
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
    hardware.graphics.intel = true;
    machine.nix.cache.enable = true;
  };
}
