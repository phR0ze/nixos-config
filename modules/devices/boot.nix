# Grub bootloader configuration
#
# ### Options
# - devices.boot.efi: enable EFI boot support (mutually exclusive with devices.boot.mbr)
# - devices.boot.mbr: BIOS MBR boot device e.g. '/dev/sda' (mutually exclusive with devices.boot.efi)
#
# Both default to inert values ('efi = false', 'mbr = "nodev"'), so a host that sets neither (e.g. a
# VM or ISO) leaves grub untouched entirely.
# --------------------------------------------------------------------------------------------------
{ config, lib, ... }: with lib.types;
let
  cfg = config.devices.boot;
in
{
  options.devices.boot = {
    efi = lib.mkOption {
      type = bool;
      default = false;
      description = "Enable EFI boot support";
    };
    mbr = lib.mkOption {
      type = str;
      default = "nodev";
      description = "BIOS MBR boot device e.g. '/dev/sda', or 'nodev' to disable BIOS MBR support";
    };
  };

  config = lib.mkIf (cfg.efi || cfg.mbr != "nodev") {
    assertions = [
      { assertion = !(cfg.efi && cfg.mbr != "nodev");
        message = "devices.boot.efi and devices.boot.mbr are mutually exclusive - set only one"; }
    ];

    boot.loader = {
      grub.enable = true;

      # Defaults to '/boot' and only gets used if efiSupport is true
      efi.efiSysMountPoint = "/boot";
      grub.efiSupport = cfg.efi;

      # i.e. EFI/BOOT/BOOTX64.efi
      grub.efiInstallAsRemovable = cfg.efi;

      # Configure the BIOS MBR boot device, e.g. '/dev/sda'
      grub.device = cfg.mbr;
    };
  };
}
