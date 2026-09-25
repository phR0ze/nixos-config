# Family15 configuration
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
    host.desktop.xfce.standard = true;

    host.boot.efi = true;
    devices.gpu.intel.enable = true;
    host.nix.cache.enable = true;

    devices.printers.epson-wf7710 = true;
    devices.printers.brother-hll2405w = true;
  };
}
