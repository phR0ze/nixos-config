# Family19 configuration
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
    devices.boot.efi = true;
    host.nix.cache.enable = true;
    host.smb.secrets = ./secrets.enc.yaml;   # real per-share passwords (lydia)
    devices.gpu.nvidia = { enable = true; open = true; };

    apps.games.roblox.enable = true;
  };
}
