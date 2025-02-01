{
  # General configuration
  # ------------------------------------------------------------------------------------------------
  hostname = "nixos";               # Hostname for the machine
  profile = "xfce/desktop";         # Pre-defined configurations in path './profiles' selection
  efi = false;                      # EFI system boot type set during installation
  mbr = "nodev";                    # MBR system boot device set during installation, e.g. /dev/sda
  arch = "x86_64-linux";            # System architecture to use
  drive0_uuid = "";                 # Drive 0 identifier used in hardware-configuration.nix
  drive1_uuid = "";                 # Drive 1 identifier used in hardware-configuration.nix
  drive2_uuid = "";                 # Drive 2 identifier used in hardware-configuration.nix
  locale = "en_US.UTF-8";           # Locale selection
  timezone = "America/Boise";       # Time-zone selection
  bluetooth = false;                # Enable or disable bluetooth by default
  autologin = false;                # Automatically log the user in or not after boot
  resolution_x = 0;                 # Resolution x dimension, e.g. 1920
  resolution_y = 0;                 # Resolution y dimension, e.g. 1080
  iso_mode = false;                 # Enable or disable ISO mode
  nix_base = "24.05";               # NixOS base install version

  # Services configuration
  # ------------------------------------------------------------------------------------------------
  samba_enable = false;             # Enable pre-configured samba shares for this system
  nfs_enable = false;               # Enable pre-configured nfs shares for this system
  nix_cache_enable = false;         # Enable using the local Nix binary cache
  nix_cache_ip = "";                # IP address of the local Nix binary cache

  # User configuration
  # ------------------------------------------------------------------------------------------------
  user_fullname = "";               # User's fullname, set in args.enc.yaml
  user_email = "";                  # User's email address, set in args.enc.yaml
  user_name = "admin";              # User's user name, set in args.enc.yaml
  user_pass = "admin";              # User's password, set in args.enc.yaml

  # Git configuration
  # ------------------------------------------------------------------------------------------------
  git_user = "";                    # Git user name to use as global configuration
  git_email = "";                   # Git email address to use as global configuration
  git_comment = "";                 # Commit message for simple version tracking

  # Network configuration
  # ------------------------------------------------------------------------------------------------
  nic0_name = "";                   # First NIC found in hardware-configuration.nix
  nic0_ip = "";                     # IP address for nic 0 if given else DHCP, e.g. 192.168.1.12/24
  nic0_subnet = "";                 # Subnet to use for machine e.g. `192.168.1.0/24`
  nic0_gateway = "";                # Gateway to use for machine e.g. `192.168.1.1`
  nic1_name = "";                   # Second NIC found in hardware-configuration.nix
  nic1_ip = "";                     # IP address for nic 0 if given else DHCP, e.g. 192.168.1.12/24
  nic1_subnet = "";                 # Subnet to use for machine e.g. `192.168.1.0/24`
  nic1_gateway = "";                # Gateway to use for machine e.g. `192.168.1.1`
  macvtap_host = "";                # NIC name on the host to attach taps to e.g. 'enp1s0'
  dns_primary = "1.1.1.1";          # Primary DNS to use for machine e.g. `1.1.1.1`
  dns_fallback = "8.8.8.8";         # Fallback DNS to use for machine e.g. `8.8.8.8`
}
