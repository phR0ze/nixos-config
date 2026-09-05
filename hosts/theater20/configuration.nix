# Theater20 configuration
#
# ### Features
# - Theater focused desktop deployment
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../layers/bundles/xfce-theater.nix
  ];

  config = {
    host.type.bootable = true;
    devices.gpu.intel.enable = true;
    host.autologin = true;
    host.nix.cache.enable = true;
    host.smb.secrets = ./secrets.enc.yaml;   # real per-share passwords (ashley/lydia)

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
