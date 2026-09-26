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
    host.boot.efi = true;
    host.nix.cache.enable = true;
    host.desktop.xfce.standard = true;

    devices.gpu.intel.enable = true;

    devices.printers.epson-wf7710 = true;
    devices.printers.brother-hll2405w = true;
  };
}
