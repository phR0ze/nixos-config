# Grub configuration
# --------------------------------------------------------------------------------------------------
{ args, ... }:
{
  # Configure default kernel modules
  boot.loader = {
    grub.enable = true;

    efi.efiSysMountPoint = if (args.settings.efi == true) then "/boot" else null;
    grub.efiSupport = if (args.settings.efi == true) then true else false;
    grub.efiInstallAsRemovable = if (args.settings.efi == true) then true else false; # i.e. EFI/BOOT/BOOTX64.efi

    # Configure or disable BIOS MBR boot support 
    # Will be set with automation to, e.g. '/dev/sda' (MBR), or 'nodev' (EFI)
    grub.device = args.settings.mbr;
  };
}

# vim:set ts=2:sw=2:sts=2