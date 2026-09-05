# HP Notebook configuration
#
# ### Machine specs
# -
#
# ### Features
# - Basic desktop deployment
# --------------------------------------------------------------------------------------------------
{ config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/xfce/laptop.nix
  ];

  config = {
    machine.type.bootable = true;
    machine.nix.cache.enable = true;
    machine.secrets = ./secrets.enc.yaml;   # real per-machine password (differs from shared default)
    machine.smb.secrets = ./secrets.enc.yaml;
    apps.network.rustdesk.secrets = ./secrets.enc.yaml;

    boot.kernelModules = [ "wl"];
    boot.extraModulePackages = [
      config.boot.kernelPackages.broadcom_sta
    ];
    boot.blacklistedKernelModules = [ "b43" "bcma" ];
  };
}
