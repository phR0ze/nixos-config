# Theater20 configuration
#
# ### Features
# - Theater focused desktop deployment
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/xfce/theater.nix
  ];

  config = {
    machine.type.bootable = true;
    devices.gpu.intel = true;
    machine.autologin = true;
    machine.nix.cache.enable = true;

    apps.games.hedgewars.enable = true;
    apps.games.superTuxKart.enable = true;
  };
}
