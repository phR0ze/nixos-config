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
    ../../profiles/xfce/desktop.nix
  ];

  config = {
    machine.type.bootable = true;
    machine.nix.cache.enable = true;
    machine.secrets = ../../secrets.enc.yaml;   # shared default (user.password/passwordHash)
    machine.smb.secrets = ./secrets.enc.yaml;   # real per-share passwords (lydia)
    apps.network.rustdesk.secrets = ./secrets.enc.yaml;   # machine-specific (tied to machine.id)
    devices.gpu.nvidia = { enable = true; open = true; };

    apps.games.roblox.enable = true;
  };
}
