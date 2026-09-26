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
  ];

  config = {
    host.boot.efi = true;
    host.nix.cache.enable = true;
    host.desktop.xfce.standard = true;

    devices.gpu.nvidia = { enable = true; open = true; };

    # Pre-generate thumbnails via tumblerd; run: gen-thumbs /mnt/Data
    apps.media.gen-thumbs.enable = true;

    services.native.smb.enable = true;
  };
}
