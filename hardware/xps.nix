# Generic hardware configuration
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, modulesPath, ... }:
{
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.kernelModules = [ "kvm-intel" ]; 
}

# vim:set ts=2:sw=2:sts=2
