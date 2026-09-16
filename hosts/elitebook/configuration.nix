# EliteBook configuration
#
# ### Machine specs
# - Nvidia Quadro FX 880M => Legacy 340
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
    devices.boot.mbr = "/dev/sda";
    host.nix.cache.enable = true;

    # Broken
    #devices.gpu.nvidia = { enable = true; legacy340 = true; };
  };
}
