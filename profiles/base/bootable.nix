# Minimal bootable configuration
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
{ args, config, lib,  ... }: with lib;
{
  imports = [
    ./minimal.nix
    ../../system/boot/initrd.nix
    ../../system/locale.nix
    ../../system/shell/bash.nix
    ../../system/users.nix
    ../../system/security/sudo.nix
    ../../system/services/sshd.nix
    ../../system/nix.nix
    ../../system/networking/base.nix
  ];

  # Bootable systems imply a more general use case. Overriding the minimal.nix to include:
  # - docs, basic services
  config = {
    documentation.enable = lib.mkOverride 500 true;
    documentation.doc.enable = lib.mkOverride 500 true;
    documentation.info.enable = lib.mkOverride 500 true;
    documentation.man.enable = lib.mkOverride 500 true;
    documentation.nixos.enable = lib.mkOverride 500 true;
    services.logrotate.enable = lib.mkOverride 500 true;
    services.udisks2.enable = lib.mkOverride 500 true;

    # Set the NixOS version that this was installed with
    system.stateVersion = args.systemSettings.stateVersion;
  };
}

# vim:set ts=2:sw=2:sts=2
