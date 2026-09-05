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
    ../../layers/bundles/xfce-laptop.nix
  ];

  config = {
    host.type.bootable = true;
    host.nix.cache.enable = true;
    host.secrets = ./secrets.enc.yaml;   # real per-machine password (differs from shared default)
    host.smb.secrets = ./secrets.enc.yaml;
    apps.network.rustdesk.secrets = ./secrets.enc.yaml;

    boot.kernelModules = [ "wl"];
    boot.extraModulePackages = [
      config.boot.kernelPackages.broadcom_sta
    ];
    boot.blacklistedKernelModules = [ "b43" "bcma" ];
  };
}
