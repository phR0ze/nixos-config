{
  # User set installer options
  # -----------------------------------------------------------------------------------------------
  fullname = "admin";               # user's full name to use for general purposes
  email = "nixos@nixos.org";        # email to use for general configuration
  username = "admin";               # initial admin user to create during install
  userpass = "admin";               # admin user password securely entered during boot
  git_user = "admin";               # username to use for github, gitlab or other git tools
  git_email = "nixos@nixos.org";    # email to use for github, gitlab or other git tools

  hostname = "nixos";               # hostname to use for the install
  subnet = "";                      # network cidr address e.g. 192.168.1.0/24
  gateway = "";                     # network gateway e.g. 192.168.1.1
  ip = "";                          # static ip to use if set e.g. 192.168.1.2/24
  primary_dns = "";                 # primary dns server to use e.g. 1.1.1.1
  fallback_dns = "";                # fallback dns server to use e.g. 8.8.8.8
  bluetooth = false;                # flag to control bluetooth enablement

  profile = "generic/desktop";      # pre-defined configurations in path './profiles' selection
  nfs_shares = false;               # enable the nfs client shares for this system
  autologin = false;                # automatically log the user in after boot when true

  # Automated installer options
  # -----------------------------------------------------------------------------------------------
  efi = false;                      # EFI system boot type, default "false"
  mbr = "nodev";                    # MBR system boot device, e.g. /dev/sda, default "nodev"
  nic0 = "";                        # First NIC found in hardware-configuration.nix
  nic1 = "";                        # Second NIC found in hardware-configuration.nix
  system = "x86_64-linux";          # system architecture to use
  timezone = "America/Boise";       # time-zone selection
  locale = "en_US.UTF-8";           # locale selection
  stateVersion = "24.05";           # Base install version, not sure this matters when on flake
  comment = "";                     # Placeholder for injected nixos-config comment

  # Virtual machines systemd units
  # - prior to `clu update system` build the vms with `clu build vm --help`
  # -----------------------------------------------------------------------------------------------
  vms = [
    { enable = false; hostname = "nixos70"; }
    { enable = false; hostname = "nixos71"; }
  ];
}
