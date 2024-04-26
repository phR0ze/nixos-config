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
{ config, lib, pkgs, args, ... }:
{
  imports = [
    ../locale.nix
    ../nix.nix
    ../users.nix
    ../boot/kernel.nix
    ./env.nix
    ./bash.nix
    ./starship.nix
    ../network
    ../development/git.nix
    ../development/neovim.nix
    ../services/nfs.nix
    ../services/sshd.nix
    ../services/systemd.nix

  # conditionally exclude grub for iso builds
  ] ++ lib.optional (!args.iso) ../boot/grub.nix;


  # Install hardware firmware
  # https://github.com/NixOS/nixpkgs/blob/release-23.11/nixos/modules/hardware/all-firmware.nix
  hardware.firmware = with pkgs; [
    linux-firmware
    alsa-firmware
  ];

  # Install useful system packages
  environment.systemPackages = with pkgs; [

    # Networking utilities
    git                           # The fast distributed version control system
    nfs-utils                     # Support programs for Network File Systems
    wget                          # Retrieve files using HTTP, HTTPS, and FTP

    # System utilities
    efibootmgr                    # EFI Boot Manager
    efivar                        # Tools to manipulate EFI variables
    cdrtools                      # ISO tools e.g. isoinfo, mkisofs
    ddrescue                      # GNU ddrescue, a data recovery tool
    dos2unix                      # Text file format converter
    #fwupd                         # Firmware update tool (NixOS requires building this?????)
    gptfdisk                      # Disk tools e.g. sgdisk, gdisk, cgdisk
    #'intel-ucode'               # required for Intel Microcode update files to boot
    inxi                          # CLI system information tool
    jq                            # Command line JSON processor, depof: kubectl
    libisoburn                    # xorriso ISO creation tools
    logrotate                     # Rotates and compresses system logs
    nix-prefetch                  # Utility to fetch git source to compute hashes
    #'mkinitcpio-vt-colors'      # vt-colors, mkintcpio, find, xargs, gawk, grep
    psmisc                        # Proc filesystem utilities e.g. killall
    smartmontools                 # Monitoring tools for hard drives
    squashfsTools                 # mksquashfs, unsquashfs
    testdisk                      # Checks and undeletes partitions + photorec
    tmux                          # Terminal multiplexer
    tree                          # Simple dir listing app in tree form
    usbutils                      # Tools for working with USB devices e.g. lsusb
    yq                            # Command line YAML/XML/TOML processor

    # Compression utilities
    p7zip                         # Comman-line file archiver for 7zip format, depof: thunar
    unrar                         # Unfree utility to uncompress RAR archives
    unzip                         # Uncompress Zip archives
    zip                           # Create zip archives
  ];

  # Set the NixOS version that this was installed with
  system.stateVersion = args.settings.stateVersion;
}
