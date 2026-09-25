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
    host.boot.efi = true;
    host.autologin = true;
    host.nix.cache.enable = true;
    host.desktop.xfce.theater = true;

    devices.gpu.intel.enable = true;

    apps.dev.rust.enable = true;
    apps.dev.flutter.enable = true;
    apps.games.hedgewars.enable = true;
    apps.games.superTuxKart.enable = true;

    services.native.keyd.enable = true;
  };
}
