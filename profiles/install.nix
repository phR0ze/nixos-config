# Installation argument override template
# - during install this file will be copied to the root and populated with install argument overrides 
# --------------------------------------------------------------------------------------------------
{
  # General overrides
  # ------------------------------------------------------------------------------------------------
  hostname = "nixos";                   # Hostname for the machine
  id = "";                              # Generated machine ID to use for the system
  efi = false;                          # EFI system boot type set during installation
  mbr = "nodev";                        # MBR system boot device set during installation, e.g. /dev/sda
  arch = "x86_64-linux";                # System architecture to use
  locale = "en_US.UTF-8";               # Locale selection
  timezone = "America/Boise";           # Time-zone selection
  bluetooth = false;                    # Enable or disable bluetooth by default
  autologin = false;                    # Automatically log the user in or not after boot
  resolution.x = 0;                     # Machine X resolution e.g. 1920
  resolution.y = 0;                     # Machine Y resolution e.g. 1080
  type.bootable = true;                 # Machine requireas a bootloader
  type.develop = false;                 # Machine is intended to be used for development
  type.theater = false;                 # Machine is intended to be used for media
  nix.minVer = "25.05";                 # Nixpkgs minimum version
  drives = [];                          # List of drives to configure in hardware-configuration.nix

  # User overrides
  # ------------------------------------------------------------------------------------------------
	user.name = "nixos";                  # Default user name
  user.fullname = "nixos";              # Default user full name
	user.email = "nixos";                 # Default user email address
	user.pass = "nixos";                  # Default user password
	git.user = "nixos";                   # Default github account user name
	git.group = "nixos";                  # Default github account user name
  git.email = "nixos";                  # Default github account user email

  # Networking overrides
  # ------------------------------------------------------------------------------------------------
  net.subnet = "";
  net.gateway = "";
  net.dns.primary = "1.1.1.1";          # Default primary DNS to use for machine e.g. `1.1.1.1`
  net.dns.fallback = "8.8.8.8";         # Default fallback DNS to use for machine e.g. `8.8.8.8`
  net.nic0.name = "";                   # NIC system identifier e.g. ens18, eth0
  net.nic0.ip = "";                     # IP address to use for this NIC else DHCP, e.g. 192.168.1.12/24
  net.nic0.gateway = "";                # Default gateway to use for machine e.g. `192.168.1.1`
  net.nic0.subnet = "";                 # Default subnet to use for machine e.g. `192.168.1.0/24`
  net.nic0.dns.primary = "1.1.1.1";     # Default primary DNS to use for machine e.g. `1.1.1.1`
  net.nic0.dns.fallback = "8.8.8.8";    # Default fallback DNS to use for machine e.g. `8.8.8.8`

  # Service overrides
  # ------------------------------------------------------------------------------------------------
  smb.enable = false;                   # Enable pre-configured samba shares for this system
  nfs.enable = false;                   # Enable pre-configured nfs shares for this system
  nix.cache.enable = false;             # Enable using the local Nix binary cache
}
