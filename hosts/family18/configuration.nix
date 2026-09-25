# Family18 configuration
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
  ];

  config = {
    devices.boot.efi = true;
    host.desktop.xfce.standard = true;
    host.nix.cache.enable = true;
    devices.gpu.nvidia = { enable = true; open = true; };

    apps.games.roblox.enable = true;
  };
}
