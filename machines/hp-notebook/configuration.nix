# HP Notebook configuration
#
# ### Machine specs
# -
#
# ### Features
# - Basic desktop deployment
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/xfce/laptop.nix
  ];

  config = {
    machine.type.bootable = true;
    machine.nix.cache.enable = true;

    boot.kernelModules = [ "wl"];
    boot.extraModulePackages = [
      config.boot.kernelPackages.broadcom_sta
    ];
    boot.blacklistedKernelModules = [ "b43" "bcma" ];
  };
}
