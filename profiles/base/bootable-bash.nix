# Minimal bootable bash configuration
#
# ### Features
# - Size: 1030.3 MiB
# - Configured by flake args
#   - Grub EFI/MBR bootable
#   - System/User Locale
#   - Default user/admin
#   - Hostname
#   - Disable IPv5 networking
# - Bash custom user configuration
# - Passwordless access for Sudo for default user
# - SSHD custom configuration
# - Nix flake and commands configuration
# - DHCP systemd-networkd networking
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  imports = [
#    ./minimal.nix
    "${args.nixpkgs}/nixos/modules/profiles/minimal.nix"
    ../../system/boot/initrd.nix
    ../../system/locale.nix
    ../../system/shell/bash.nix
    ../../system/users.nix
    ../../system/security/sudo.nix
    ../../system/services/sshd.nix
    ../../system/nix.nix
    ../../system/networking/base.nix
  ];

  # Set the NixOS version that this was installed with
  config.system.stateVersion = args.systemSettings.stateVersion;
}

# vim:set ts=2:sw=2:sts=2
