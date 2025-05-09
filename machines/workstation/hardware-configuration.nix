{ config, lib, pkgs, modulesPath, ... }:
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
    device = "/dev/disk/by-uuid/${(builtins.elemAt config.machine.drives 0).uuid}";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/EED1-1E99";
    fsType = "vfat";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/64b00b8b-00a0-4b92-b273-46559044ad50"; }
  ];

  fileSystems."/mnt/storage1" = {
    device = "/dev/disk/by-uuid/${(builtins.elemAt config.machine.drives 1).uuid}";
    fsType = "ext4";
  };

  fileSystems."/mnt/storage2" = {
    device = "/dev/disk/by-uuid/${(builtins.elemAt config.machine.drives 2).uuid}";
    fsType = "ext4";
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp1s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
