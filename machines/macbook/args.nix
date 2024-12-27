{
  hostname = "macbook";             # hostname for the machine
  nfs = false;                      # enable the nfs client shares for this system
  autologin = false;                # automatically log the user in after boot when true

  efi = true;                       # EFI system boot type, default "false"
  mbr = "nodev";                    # MBR system boot device, e.g. /dev/sda, default "nodev"
  nic0 = "ens18";                   # First NIC found in hardware-configuration.nix
}
