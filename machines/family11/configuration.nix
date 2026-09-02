# Family11 configuration
#
# ### Machine specs
# - ?
#
# ### Features
# - Basic desktop deployment
# - RTL8822BU USB WiFi (0bda:b812) via in-kernel rtw88_8822bu driver
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
    machine.smb.secrets = ./secrets.enc.yaml;   # real per-share passwords (ashley/lydia)
    apps.network.rustdesk.secrets = ./secrets.enc.yaml;   # machine-specific (tied to machine.id)
    devices.gpu.nvidia = { enable = true; open = true; };

    apps.dev.claude.enable = true;

    # Pre-generate thumbnails via tumblerd; run: gen-thumbs /mnt/Data
    apps.media.gen-thumbs.enable = true;
  };
}
