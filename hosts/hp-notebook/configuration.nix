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

    # broadcom_sta is an insecure package (upstream, unmaintained driver) - allowed only here
    # since only this host's wifi card needs it
    nixpkgs.config.permittedInsecurePackages = [ "broadcom-sta-6.30.223.271-57-6.12.41" ];
    boot.kernelModules = [ "wl"];
    boot.extraModulePackages = [
      config.boot.kernelPackages.broadcom_sta
    ];
    boot.blacklistedKernelModules = [ "b43" "bcma" ];
  };
}
