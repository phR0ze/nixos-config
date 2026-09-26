{ config, lib, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "ata_generic" "ehci_pci" "ahci" "isci" "xhci_pci"
    "firewire_ohci" "usb_storage" "usbhid" "sd_mod" "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/${(builtins.elemAt config.host.drives 0).uuid}";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/17AD-69A9";
    fsType = "vfat";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/819b5842-b516-4772-b83d-96916f1822af"; }
  ];

  fileSystems."/mnt/storage1" = {
    device = "/dev/disk/by-uuid/${(builtins.elemAt config.host.drives 1).uuid}";
    fsType = "ext4";
  };

  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp1s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
