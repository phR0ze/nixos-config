# Grub configuration
# --------------------------------------------------------------------------------------------------
{ lib, args, ... }:
{
  # Configure default kernel modules
  boot.loader = {
    grub.enable = true;

    # Defaults to '/boot' and only gets used if efiSupport is true
    efi.efiSysMountPoint = "/boot";
    grub.efiSupport = lib.mkIf args.settings.efi true;

    # i.e. EFI/BOOT/BOOTX64.efi
    grub.efiInstallAsRemovable = lib.mkIf args.settings.efi true;

    # Configure or disable BIOS MBR boot support 
    # Will be set with automation to, e.g. '/dev/sda' (MBR), or 'nodev' (EFI)
    grub.device = args.settings.mbr;
  };
}
