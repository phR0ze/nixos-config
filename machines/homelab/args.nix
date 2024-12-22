{
  hostname = "homelab";             # hostname for the machine
  nfs = false;                      # enable the nfs client shares for this system
  autologin = false;                # automatically log the user in after boot when true

  efi = false;                      # EFI system boot type, default "false"
  mbr = "/dev/sda";                 # MBR system boot device, e.g. /dev/sda, default "nodev"
  nic0 = "ens18";                   # First NIC found in hardware-configuration.nix
  nic1 = "";                        # Second NIC found in hardware-configuration.nix

  # Virtual machines systemd units
  # - prior to `clu update system` build the vms with `clu build vm --help`
  # -----------------------------------------------------------------------------------------------
  vms = [
    { enable = false; hostname = "nixos70"; }
    { enable = false; hostname = "nixos71"; }
  ];
}
