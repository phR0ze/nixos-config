# Family12 configuration
#
# ### Machine specs
# - ?
#
# ### Features
# - Basic desktop deployment
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../layers/bundles/xfce-desktop.nix
  ];

  config = {
    host.type.bootable = true;
    host.nix.cache.enable = true;
    devices.gpu.nvidia = { enable = true; open = true; };

    apps.games.roblox.enable = true;
  };
}
