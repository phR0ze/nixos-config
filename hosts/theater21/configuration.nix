# Theater20 configuration
#
# ### Features
# - Theater focused desktop deployment
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  config = {
    devices.boot.efi = true;
    devices.gpu.intel.enable = true;
    host.desktop.xfce.theater = true;
    host.autologin = true;
    host.nix.cache.enable = true;

    apps.games.hedgewars.enable = true;
    apps.games.superTuxKart.enable = true;
  };
}
