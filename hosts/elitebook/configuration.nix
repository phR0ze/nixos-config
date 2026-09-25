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
  ];

  config = {
    host.boot.mbr = "/dev/sda";
    host.nix.cache.enable = true;
    host.desktop.xfce.standard = true;

    # Broken
    #devices.gpu.nvidia = { enable = true; legacy340 = true; };
  };
}
