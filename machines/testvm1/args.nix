{
  cores = 4;                        # Cores to use
  diskSize = 1;                     # Disk size in GiB
  memorySize = 4;                   # Memory size in GiB
  resolution.x = 1920;              # Resolution x dimension
  resolution.y = 1080;              # Resolution y dimension
  hostname = "homelab";             # hostname for the machine
  nfs = false;                      # enable the nfs client shares for this system
  autologin = true;                 # automatically log the user in after boot when true

  efi = false;                      # EFI system boot type, default "false"
  mbr = "/dev/sda";                 # MBR system boot device, e.g. /dev/sda, default "nodev"
  nic0 = "eth0";                    # Nic override for VM
}
