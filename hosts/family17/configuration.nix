# Family17 configuration
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
    host.boot.efi = true;
    host.nix.cache.enable = true;
    host.desktop.xfce.standard = true;

    devices.gpu.nvidia = { enable = true; open = true; };

    services.native.firefight.client.enable = true;
    apps.games.roblox.enable = true;
  };
}
