# Minimal base bootable configuration
#
# ### Features
# - Directly installable
# - Size: 1511.2 MiB
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
{ config, lib, pkgs, args, ... }:
{
  imports = [
    ./minimal.nix
    ../../modules
    ../../modules/boot
    ../../modules/terminal
    ../../modules/networking
    ../../modules/development
    ../../modules/services/sshd.nix
    ../../home-manager
  ];

  environment.systemPackages = with pkgs; [

    # Networking utilities
    git
    wget

    # System utilities
    efibootmgr
    efivar
    #'cdrtools'                  # isoinfo, mkisofs
    ddrescue
    #'dos2unix'                  # Text file format converter
    #'intel-ucode'               # required for Intel Microcode update files to boot
    inxi
    #'linux-firmware'            # Fills in missing drivers for initramfs builds
    logrotate
    #'mkinitcpio-vt-colors'      # vt-colors, mkintcpio, find, xargs, gawk, grep
    psmisc
    smartmontools
    tmux
    usbutils
    yq

    # Compression utilities
    unrar
    unzip
    zip
  ];

  # Bootable systems imply a more general use case. Overriding the minimal.nix to include
  # docs and basic services; however this adds a full 500 MiB to the installation.
  documentation.enable = lib.mkOverride 500 true;
  documentation.doc.enable = lib.mkOverride 500 true;
  documentation.info.enable = lib.mkOverride 500 true;
  documentation.man.enable = lib.mkOverride 500 true;
  documentation.nixos.enable = lib.mkOverride 500 true;

  # Set the NixOS version that this was installed with
  system.stateVersion = args.settings.stateVersion;
}

# vim:set ts=2:sw=2:sts=2
