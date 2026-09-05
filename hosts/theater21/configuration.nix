# Theater20 configuration
#
# ### Features
# - Theater focused desktop deployment
# --------------------------------------------------------------------------------------------------
{ ... }:
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
    host.secrets = ../../secrets.enc.yaml;   # shared default (user.password/passwordHash)
    apps.network.rustdesk.secrets = ./secrets.enc.yaml;   # machine-specific (tied to host.id)

    apps.games.hedgewars.enable = true;
    apps.games.superTuxKart.enable = true;
  };
}
