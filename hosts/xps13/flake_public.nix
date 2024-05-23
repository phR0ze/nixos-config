{
  # Public clu installer options
  # ------------------------------------------------------------------------------------------------
  hostname = "xps13";             # hostname to use for the install
  static_ip = "";                 # static ip to use if set e.g. 192.168.1.2/24
  gateway = "";                   # default gateway to use for static ip addresses
  bluetooth = false;              # flag to control bluetooth enablement

  profile = "dell-xps-13-9310/develop";    # pre-defined configurations in path './profiles' selection
  nfs_shares = false;             # enable the nfs client shares for this system
  autologin = false;              # automatically log the user in after boot when true
  
  # Configuration set via automation in the clu installer
  # ------------------------------------------------------------------------------------------------
  efi = true;                     # EFI system boot type, default "false"
  mbr = "nodev";                  # MBR system boot device, default "nodev"
  system = "x86_64-linux";        # system architecture to use
  timezone = "America/Boise";     # time-zone selection
  locale = "en_US.UTF-8";         # locale selection
  comment = "31c1a49: Adding default dell-xps-13 hardware";                   # Placeholder for injected nixos-config comment
}
