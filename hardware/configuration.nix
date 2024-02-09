# Generic hardware configuration
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, modulesPath, ... }:
{
  #boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "usb_storage" "sd_mod" ];
}

# vim:set ts=2:sw=2:sts=2
