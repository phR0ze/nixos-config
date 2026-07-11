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
    devices.gpu.nvidia = { enable = true; open = true; };

    apps.dev.claude.enable = true;

    # Pre-generate thumbnails via tumblerd; run: gen-thumbs /mnt/Data
    apps.media.gen-thumbs.enable = true;
  };
}
