# Family11 configuration
#
# ### Features
# - Basic desktop deployment
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/xfce/desktop.nix
  ];

  config = {
    machine.type.bootable = true;
    machine.nix.cache.enable = true;
    apps.games.warcraft2.enable = true;
    devices.gpu.nvidiaLegacy470 = true;
  };
}
