# ISO Nix Store packages
# --------------------------------------------------------------------------------------------------
# Including package dependencies in the ISO Nix store to avoid having to download them at install 
# time. This will dramatically speed up the install time and avoid spotty internet or slow download 
# times. This list isn't comprehensive as many basic packages are included in the ISO Nix store by 
# default.
#
# ### References
# * [Live NixOS ISO](https://nixos.wiki/wiki/Creating_a_NixOS_live_CD)
# * [ISO Image Construction](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/cd-dvd/iso-image.nix
# --------------------------------------------------------------------------------------------------
{ config, pkgs, ... }:
{
  # Not including packages already included by default with minimal ISO
  isoImage.storeContents = with pkgs; [
    config.system.build.toplevel  # default ISO inclusion

    # CLI dependencies
    # ----------------------------------------------------------------------------------------------

    # Firmware
    linux-firmware                # 
    alsa-firmware                 #

    # System utilities
    efibootmgr                    # EFI Boot Manager
    efivar                        # Tools to manipulate EFI variables
    cdrtools                      # ISO tools e.g. isoinfo, mkisofs
    ddrescue                      # GNU ddrescue, a data recovery tool
    dos2unix                      # Text file format converter
    #fwupd                         # Firmware update tool (NixOS requires building this?????)
    gptfdisk                      # Disk tools e.g. sgdisk, gdisk, cgdisk
    grub2                         # GNU GRUB, the Grand Unified Boot Loader
    #'intel-ucode'                 # required for Intel Microcode update files to boot
    inxi                          # CLI system information tool
    jq                            # Command line JSON processor, depof: kubectl
    libisoburn                    # xorriso ISO creation tools
    logrotate                     # Rotates and compresses system logs
    nix-prefetch                  # Utility to fetch git source to compute hashes
    #'mkinitcpio-vt-colors'        # vt-colors, mkintcpio, find, xargs, gawk, grep
    psmisc                        # Proc filesystem utilities e.g. killall
    smartmontools                 # Monitoring tools for hard drives
    squashfsTools                 # mksquashfs, unsquashfs
    starship                      # A minimal, blazing fast, and extremely customizable prompt for any shell
    testdisk                      # Checks and undeletes partitions + photorec
    tmux                          # Terminal multiplexer
    tree                          # Simple dir listing app in tree form
    usbutils                      # Tools for working with USB devices e.g. lsusb
    yq                            # Command line YAML/XML/TOML processor

    # Networking utilities
    git                           # The fast distributed version control system
    nfs-utils                     # Support programs for Network File Systems
    rsync                         # A fast and versatile file copying tool for remote and local files
    wget                          # Retrieve files using HTTP, HTTPS, and FTP

    # Development utilities
    neovim                        # Fork of Vim aiming to improve user experience, plugins, and GUIs

    # Compression utilities
    p7zip                         # Comman-line file archiver for 7zip format, depof: thunar
    unrar                         # Unfree utility to uncompress RAR archives
    unzip                         # Uncompress Zip archives
    zip                           # Create zip archives

    # X11 dependencies
    # ----------------------------------------------------------------------------------------------
    vscodium                      # Open source version of Microsoft's vscode without phone home
    pavucontrol                   # PulseAudio Volume Control
    pulseaudioFull                # Sound server for POSIX and Win32 systems
    blueman                       # GTK-based Bluetooth Manager
    bluez                         # Daemon for the bluetooth protocol stack

    # XFCE dependencies
    # ----------------------------------------------------------------------------------------------
    xfce.xfconf                   # Simple client-server configuration storage and query system for Xfce


    # Other not sure needed
    #fontconfig
    #getconf-glibc
    #hicolor-icon-theme
    #nix-prefetch
    #nixos-container
    #shared-mime-info
    #sound-theme-freedesktop
    #strace
    #texinfo-interactive
  ];
}
