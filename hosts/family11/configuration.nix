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
    ../../layers/bundles/xfce-desktop.nix
  ];

  config = {
    host.type.bootable = true;
    host.nix.cache.enable = true;
    host.smb.secrets = ./secrets.enc.yaml;   # real per-share passwords (ashley/lydia)
    devices.gpu.nvidia = { enable = true; open = true; };

    apps.dev.claude.enable = true;

    # Pre-generate thumbnails via tumblerd; run: gen-thumbs /mnt/Data
    apps.media.gen-thumbs.enable = true;
  };
}
