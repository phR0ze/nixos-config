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
    host.type.bootable = true;
    host.nix.cache.enable = true;
    host.secrets = ../../secrets.enc.yaml;   # shared default (user.password/passwordHash)
    host.smb.secrets = ./secrets.enc.yaml;   # real per-share passwords (lydia)
    apps.network.rustdesk.secrets = ./secrets.enc.yaml;   # machine-specific (tied to host.id)
    devices.gpu.nvidia = { enable = true; open = true; };

    apps.games.roblox.enable = true;
  };
}
