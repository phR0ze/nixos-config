# This file is used to seed your configuration with defaults for your systems, rather than having
# to dig into options/types/machine.nix and manually make changes there.
#
# Note:
# - this is the lowes priority configuration file and all other overrides take precedent
# --------------------------------------------------------------------------------------------------
{
  id = "";                              # Machine id for the system
  target = "profiles/xfce/desktop.nix"; # Pre-defined configurations './machines' or './profiles'
  hostname = "nixos";                   # Hostname for the machine
  efi = false;                          # EFI system boot type set during installation
  mbr = "nodev";                        # MBR system boot device set during installation, e.g. /dev/sda
  arch = "x86_64-linux";                # System architecture to use
  locale = "en_US.UTF-8";               # Locale selection
  timezone = "America/Boise";           # Time-zone selection
  bluetooth = false;                    # Enable or disable bluetooth by default
  autologin = false;                    # Automatically log the user in or not after boot
  type.iso = false;                     # Enable or disable ISO mode
  resolution.x = 0;                     # Machine X resolution e.g. 1920
  resolution.y = 0;                     # Machine Y resolution e.g. 1080
  nix.minVer = "25.05";                 # Nixpkgs minimum version
  drives = [];                          # List of drives to configure in hardware-configuration.nix
  git.comment = "";

  # Services configuration
  # ------------------------------------------------------------------------------------------------
  smb.enable = false;               # Enable pre-configured samba shares for this system
  nfs.enable = false;               # Enable pre-configured nfs shares for this system
  nix.cache.enable = false;         # Enable using the local Nix binary cache
}
