# Theater20 configuration
#
# ### Features
# - Theater focused desktop deployment
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
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

    services.raw.keyd.enable = true;
    apps.games.hedgewars.enable = true;
    apps.games.superTuxKart.enable = true;

    development.rust.enable = true;
    development.flutter.enable = true;

    environment.systemPackages = [
      pkgs.rust-analyzer
    ];
  };
}
