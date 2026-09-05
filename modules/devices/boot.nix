{ config, lib, ... }:
let
  host = config.host;
in
{
  # Grub configuration for non VM/ISO machines
  config = lib.mkIf (!host.type.vm && !host.type.iso) {
    boot.loader = {
      grub.enable = true;

      # Defaults to '/boot' and only gets used if efiSupport is true
      efi.efiSysMountPoint = "/boot";
      grub.efiSupport = lib.mkIf (host.efi) true;

      # i.e. EFI/BOOT/BOOTX64.efi
      grub.efiInstallAsRemovable = lib.mkIf (host.efi) true;

      # Configure or disable BIOS MBR boot support 
      # Will be set with automation to, e.g. '/dev/sda' (MBR), or 'nodev' (EFI)
      grub.device = host.mbr;
    };
  };
}
