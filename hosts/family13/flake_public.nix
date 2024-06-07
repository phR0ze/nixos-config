{
  # Public clu installer options
  # ------------------------------------------------------------------------------------------------
  hostname = "family13";          # hostname to use for the install
  static_ip = "192.168.1.13/24";  # static ip to use if set e.g. 192.168.1.2/24
  gateway = "192.168.1.1";        # default gateway to use for static ip addresses
  bluetooth = false;              # flag to control bluetooth enablement

  profile = "generic/desktop";    # pre-defined configurations in path './profiles' selection
  nfs_shares = true;              # enable the nfs client shares for this system
  autologin = false;              # automatically log the user in after boot when true
  
  # Configuration set via automation in the clu installer
  # ------------------------------------------------------------------------------------------------
  efi = false;                    # EFI system boot type, default "false"
  mbr = "/dev/sdb";               # MBR system boot device, default "nodev"
  system = "x86_64-linux";        # system architecture to use
  timezone = "America/Boise";     # time-zone selection
  locale = "en_US.UTF-8";         # locale selection
  comment = "";                   # Placeholder for injected nixos-config comment
}
