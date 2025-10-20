# Family15 configuration
#
# ### Features
# - Basic desktop deployment
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/xfce/desktop.nix
  ];

  config = {
    machine.type.bootable = true;
    devices.gpu.intel = true;
    machine.nix.cache.enable = true;

    devices.printers.epson-wf7710 = true;
    devices.printers.brother-hll2405w = true;
  };
}
