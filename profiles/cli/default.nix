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
    git                           # The fast distributed version control system
    wget                          # Retrieve files using HTTP, HTTPS, and FTP

    # System utilities
    efibootmgr                    # EFI Boot Manager
    efivar                        # Tools to manipulate EFI variables
    #cdrtools                      # ISO tools e.g. isoinfo, mkisofs
    ddrescue                      # GNU ddrescue, a data recovery tool
    dos2unix                      # Text file format converter
    #fwupd                         # Firmware update tool
    #gptfdisk                      # Disk tools e.g. sgdisk, gdisk, cgdisk
    #'intel-ucode'               # required for Intel Microcode update files to boot
    inxi                          # CLI system information tool
    #libisoburn                    # xorriso ISO creation tools
    #linux-firmware                # Provides a collection of hardware drivers
    logrotate                     # Rotates and compresses system logs
    #'mkinitcpio-vt-colors'      # vt-colors, mkintcpio, find, xargs, gawk, grep
    psmisc                        # Proc filesystem utilities e.g. killall
    smartmontools                 # Monitoring tools for hard drives
    #squashfsTools                 # mksquashfs, unsquashfs
    testdisk                      # Checks and undeletes partitions + photorec
    tmux                          # Terminal multiplexer
    usbutils                      # Tools for working with USB devices e.g. lsusb
    yq                            # Command line YAML/XML/TOML processor

    # Compression utilities
    unrar                         # Unfree utility to uncompress RAR archives
    unzip                         # Uncompress Zip archives
    zip                           # Create zip archives
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
