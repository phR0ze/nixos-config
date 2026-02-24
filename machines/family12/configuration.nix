# Family12 configuration
#
# ### Features
# - Basic desktop deployment
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/xfce/develop.nix
  ];

  config = {
    machine.type.bootable = true;
    machine.nix.cache.enable = true;
    apps.games.warcraft2.enable = true;
    apps.games.roblox.enable = true;
  };
}
