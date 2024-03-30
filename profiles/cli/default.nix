# Minimal base bootable configuration
#
# ### Features
# - Directly installable: fully functional cli environment
# - Size: 2433.7 MiB
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
{ ... }:
{
  imports = [
    ./minimal.nix
    ../../modules/boot/grub.nix
  ];
}
