{
  hostname = "nixos";               # hostname for the machine
  bluetooth = false;                # flag to control bluetooth enablement
  nfs_shares = false;               # enable the nfs client shares for this system
  autologin = false;                # automatically log the user in after boot when true

  profile = "generic/desktop";      # pre-defined configurations in path './profiles' selection
  efi = false;                      # EFI system boot type, default "false"
  mbr = "nodev";                    # MBR system boot device, e.g. /dev/sda, default "nodev"
  nic0 = "";                        # First NIC found in hardware-configuration.nix
  nic1 = "";                        # Second NIC found in hardware-configuration.nix
  system = "x86_64-linux";          # system architecture to use
  timezone = "America/Boise";       # time-zone selection
  locale = "en_US.UTF-8";           # locale selection
  stateVersion = "24.05";           # Base install version, not sure this matters when on flake
}
