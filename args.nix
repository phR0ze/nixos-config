# This file is used to seed your configuration with defaults for your systems, rather than having
# to dig into modules/types/host.nix and manually make changes there.
#
# Note:
# - this is the lowes priority configuration file and all other overrides take precedent
# --------------------------------------------------------------------------------------------------
{
  host.id = "";                         # Machine id for the system
  host.target = "layers/bundles/xfce-desktop.nix"; # Pre-defined configurations './hosts' or './layers', used only by nixosConfigurations.install
  host.name = "nixos";                  # Fallback hostname
  host.arch = "x86_64-linux";           # System architecture to use
  host.locale = "en_US.UTF-8";          # Locale selection
  host.timezone = "America/Boise";      # Time-zone selection
  host.bluetooth = false;               # Enable or disable bluetooth by default
  host.autologin = false;               # Automatically log the user in or not after boot
  host.drives = [];                     # List of drives to configure in hardware-configuration.nix
  host.type.iso = false;                # Enable or disable ISO mode
  host.resolution.x = 0;                # Machine X resolution e.g. 1920
  host.resolution.y = 0;                # Machine Y resolution e.g. 1080
  host.nix.cache.enable = false;        # Enable using the local Nix binary cache
  host.git.user = "";                   # Git user name
  host.git.email = "";                  # Git user email
  # host.git.comment is always set from flake introspection (self.rev), not overridable here

  # User configuration
  # ------------------------------------------------------------------------------------------------
  host.user.name = "admin";             # Default user name
  host.user.pass = "admin";             # Default user password
  host.user.fullname = "admin";         # Default user full name
  host.user.email = "nixos@nixos.org";  # Default user email address

  # Services configuration
  # ------------------------------------------------------------------------------------------------
  host.services.native.smb.enable = false;  # Enable pre-configured samba shares for this system
  host.services.native.nfs.enable = false;  # Enable pre-configured nfs shares for this system
}
