{ config, lib, ... }:
let
  machine = config.machine;
in
{
  # Grub configuration for non VM/ISO machines
  config = lib.mkIf (!machine.type.vm && !machine.type.iso) {
    boot.loader = {
      grub.enable = true;

      # Defaults to '/boot' and only gets used if efiSupport is true
      efi.efiSysMountPoint = "/boot";
      grub.efiSupport = lib.mkIf (machine.efi) true;

      # i.e. EFI/BOOT/BOOTX64.efi
      grub.efiInstallAsRemovable = lib.mkIf (machine.efi) true;

      # Configure or disable BIOS MBR boot support 
      # Will be set with automation to, e.g. '/dev/sda' (MBR), or 'nodev' (EFI)
      grub.device = machine.mbr;
    };
  };
}
