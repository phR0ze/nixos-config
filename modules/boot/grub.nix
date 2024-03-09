# Grub configuration
# --------------------------------------------------------------------------------------------------
{ args, ... }:
{
  # Configure default kernel modules
  boot.loader = {
    grub.enable = true;

    # Defaults to '/boot' and only gets used if efiSupport is true
    efi.efiSysMountPoint = "/boot";
    grub.efiSupport = if args.settings.efi then true else false;

    # i.e. EFI/BOOT/BOOTX64.efi
    grub.efiInstallAsRemovable = if args.settings.efi then true else false;

    # Configure or disable BIOS MBR boot support 
    # Will be set with automation to, e.g. '/dev/sda' (MBR), or 'nodev' (EFI)
    grub.device = args.settings.mbr;
  };
}
