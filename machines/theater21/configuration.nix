# Theater20 configuration
#
# ### Features
# - Theater focused desktop deployment
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/xfce/theater.nix
  ];

  config = {
    machine.type.bootable = true;
    devices.gpu.intel.enable = true;
    machine.autologin = true;
    machine.nix.cache.enable = true;
    machine.secrets = ../../secrets.enc.yaml;   # shared default (user.password/passwordHash)
    apps.network.rustdesk.secrets = ./secrets.enc.yaml;   # machine-specific (tied to machine.id)

    apps.games.hedgewars.enable = true;
    apps.games.superTuxKart.enable = true;
  };
}
