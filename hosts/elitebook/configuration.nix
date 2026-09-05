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
    host.type.bootable = true;
    host.nix.cache.enable = true;
    host.secrets = ./secrets.enc.yaml;   # real per-machine password (differs from shared default)

    # Broken
    #devices.gpu.nvidia = { enable = true; legacy340 = true; };
  };
}
