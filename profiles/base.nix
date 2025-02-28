# base.nix provides a minimal shell environment on which to build
#
# ### Features
# - Directly installable: fully functional cli environment
# - Kernel custom configuration
# - Grub EFI/MBR bootable
# - Passwordless access for Sudo for default user
# - SSHD custom configuration
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, ... }:
let
  machine = config.machine;
in
{
  imports = [
    ./core.nix
    ../modules/locale.nix
    ../modules/nix.nix
    ../modules/terminal
    ../modules/kernel.nix
    ../modules/services/systemd.nix
  ];

  programs.tmux.enable = true;

  environment.systemPackages = with pkgs; [
    nfs-utils                     # Support programs for Network File Systems
    wget                          # Retrieve files using HTTP, HTTPS, and FTP

    # System utilities
    cdrtools                      # ISO tools e.g. isoinfo, mkisofs
    ddrescue                      # GNU ddrescue, a data recovery tool
    dos2unix                      # Text file format converter
    #fwupd                         # Firmware update tool (NixOS requires building this?????)
    gptfdisk                      # Disk tools e.g. sgdisk, gdisk, cgdisk
    #'intel-ucode'               # required for Intel Microcode update files to boot
    inxi                          # CLI system information tool
    libisoburn                    # xorriso ISO creation tools
    nix-prefetch                  # Utility to fetch git source to compute hashes
    #'mkinitcpio-vt-colors'      # vt-colors, mkintcpio, find, xargs, gawk, grep
    smartmontools                 # Monitoring tools for hard drives
    squashfsTools                 # mksquashfs, unsquashfs
    testdisk                      # Checks and undeletes partitions + photorec
    tree                          # Simple dir listing app in tree form
    usbutils                      # Tools for working with USB devices e.g. lsusb
    yq                            # Command line YAML/XML/TOML processor

    # Compression utilities
    p7zip                         # Comman-line file archiver for 7zip format, depof: thunar
    unrar                         # Unfree utility to uncompress RAR archives
    unzip                         # Uncompress Zip archives
    zip                           # Create zip archives

    # Network
    openvpn                       # An easy-to-use, robust and highly configurable VPN (Virtual Private Network)
    update-systemd-resolved       # OpenVPN systemd-resolved updater
  ]
  ++ lib.optional (!machine.type.vm) efibootmgr
  ++ lib.optional (!machine.type.vm) efivar
  ;
}
