# Self-contained defaults for the isolated vps host (see ../.isolated).
#
# Unlike every other host, vps does NOT fall back to the root ./args.nix (flake.nix's mergeArgs
# skips both root args.nix and root args.dec.yaml whenever hosts/<hostname>/.isolated exists), so
# every key that root args.nix would otherwise supply must be restated here explicitly - nothing
# should silently depend on the fleet's shared defaults.
# --------------------------------------------------------------------------------------------------
{
  target = "hosts/vps/configuration.nix"; # Pre-defined configurations './hosts' or './layers', used only by nixosConfigurations.install
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
  git.user = "vps";                     # Git user name
  git.email = "vps@localhost";          # Git user email
  # git.comment is always set from flake introspection (self.rev), not overridable here

  # User configuration
  # ------------------------------------------------------------------------------------------------
  user.name = "admin";                  # Default user name
  user.pass = "admin";                  # Placeholder only - real password comes from args.enc.yaml
  user.fullname = "admin";              # Default user full name
  user.email = "nixos@nixos.org";       # Default user email address

  # Services configuration
  # ------------------------------------------------------------------------------------------------
  smb.enable = false;                   # Enable pre-configured samba shares for this system
  nfs.enable = false;                   # Enable pre-configured nfs shares for this system
  nix.cache.enable = false;             # Enable using the local Nix binary cache - not the fleet's shared cache
}
