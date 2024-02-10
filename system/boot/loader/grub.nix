# Grub configuration
# --------------------------------------------------------------------------------------------------
{ systemSettings, ... }:
{
  # Configure default kernel modules
  boot.loader = {
    grub.enable = true;

    #efi.efiSysMountPoint = if (systemSettings.efi == true) then "/boot" else null;
    efi.efiSysMountPoint = "/boot";
    grub.efiSupport = true;
    grub.efiInstallAsRemovable = true; # i.e. EFI/BOOT/BOOTX64.efi

    # Configure or disable BIOS MBR boot support 
    # Will be set with automation to, e.g. '/dev/sda' (MBR), or 'nodev' (EFI)
    grub.device = systemSettings.device;
  };
}

# vim:set ts=2:sw=2:sts=2
