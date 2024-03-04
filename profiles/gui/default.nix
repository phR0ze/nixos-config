# Minimal guid base configuration
#
# ### Features
# - Replicating
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
  ];


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
    #'mkinitcpio-vt-colors'      # vt-colors, mkintcpio, find, xargs, gawk, grep
    psmisc                        # Proc filesystem utilities e.g. killall
    smartmontools                 # Monitoring tools for hard drives
    squashfsTools                 # mksquashfs, unsquashfs
    testdisk                      # Checks and undeletes partitions + photorec
    tmux                          # Terminal multiplexer
    usbutils                      # Tools for working with USB devices e.g. lsusb
    yq                            # Command line YAML/XML/TOML processor

    # Compression utilities
    p7zip                         # Comman-line file archiver for 7zip format, depof: thunar
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