# Theater20 configuration
#
# ### Features
# - Theater focused desktop deployment
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
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

    services.raw.keyd.enable = true;
    apps.games.hedgewars.enable = true;
    apps.games.superTuxKart.enable = true;

    apps.dev.rust.enable = true;
    apps.dev.flutter.enable = true;

    environment.systemPackages = [
      pkgs.rust-analyzer
    ];
  };
}
