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
    ../../profiles/xfce/desktop.nix
  ];

  config = {
    machine.type.bootable = true;
    machine.nix.cache.enable = true;

    # Broken
    #devices.gpu.nvidiaLegacy340 = true;
  };
}
