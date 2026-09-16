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

    harden = lib.mkEnableOption "Enable hardening for boot";
    lowMemory = lib.mkEnableOption "Enable low memory configuration for boot";
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.efi || cfg.mbr != "nodev") {
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
    })

    # Clean /tmp on every boot
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.harden) {
      boot.tmp.cleanOnBoot = true;
    })

    # zram swap cheaply extends effective memory by taking a portion of the physical memory and
    # turning it into a compressed swap. this will allow for over doubling the available size
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.lowMemory) {
      zramSwap = {
        enable = true;
        algorithm = "zstd";                         # default compression algorithm
        memoryPercent = 50;                         # zram size relative to RAM
        priority = 100;                             # use this before disk swap
      };
    })
  ];
}
