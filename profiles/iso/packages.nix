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
  # Not sure why this is useful as it seems to include all source code for all packages which is an 
  # insane amount of space. All I want to do is include pre-built applications to speed up install 
  # similar to a nix binary cache but included in the ISO. As a result I'm not using this option and 
  # instead using the `isoImage.storeContents` option which I'll then orchestrate to with `nix copy` 
  # to pre-populate the Nix store during install.
  #isoImage.includeSystemBuildDependencies = true;

  isoImage.storeContents = with pkgs; [
    config.system.build.toplevel  # default ISO inclusion
  ];

#    acl                           # Access control list utilities, libraries and headers
#    attr                          # Extended attribute support library for ACL support
#bash-interactive                  # The GNU Bourne Again shell
#bcache-tools-1.0.7
#bind-9.18.24
#bzip2-1.0.8
#cdrtools-3.02a09
#command-not-found
#coreutils-full-9.4
#cpio-2.15
#curl-8.6.0
#dbus-1.14.10
#ddrescue-1.28
#dhcpcd-10.0.6
#diffutils-3.10
#dos2unix-7.5.2
#dosfstools-4.2
#e2fsprogs-1.47.0
#efibootmgr-18
#efivar-38
#findutils-4.9.0
#fontconfig-2.15.0
#fuse-2.9.9
#fuse-3.16.2
#gawk-5.2.2
#getconf-glibc-2.38-44
#getent-glibc-2.38-44
#git-2.43.1
#glibc-2.38-44
#glibc-locales-2.38-44
#gnugrep-3.11
#gnused-4.9
#gnutar-1.35
#gptfdisk-1.0.9
#gzip-1.13
#hicolor-icon-theme-0.17
#inxi-3.3.04-1
#iproute2-6.7.0
#iputils-20240117
#jq-1.7.1
#kbd-2.6.4
#kexec-tools-2.0.26
#kmod-31
#less-643
#libcap-2.69
#libisoburn-1.5.6
#libressl-3.8.2
#linux-pam-1.6.0
#logrotate-3.21.0
#lvm2-2.03.23
#man-db-2.12.0
#mkpasswd-5.5.21
#mount.vboxsf
#mtools-4.0.43
#nano-7.2
#ncurses-6.4
#neovim-0.9.5
#net-tools-2.10
#nfs-utils-2.6.2
#nix-2.18.1
#nix-bash-completions-0.6.8
#nix-info
#nix-prefetch-0.4.1
#nixos-build-vms
#nixos-configuration-reference-manpage
#nixos-container
#nixos-enter
#nixos-generate-config
#nixos-help
#nixos-install
#nixos-manual-html
#nixos-option
#nixos-rebuild
#nixos-version
#openresolv-3.13.2
#openssh-9.6p1
#p7zip-17.05
#patch-2.7.6
#perl-5.38.2
#procps-3.3.17
#psmisc-23.6
#rsync-3.2.7
#shadow-4.14.3
#shared-mime-info-2.4
#smartmontools-7.4
#sound-theme-freedesktop-0.8
#squashfs-4.6.1
#starship-1.17.1
#strace-6.7
#sudo-1.9.15p5
#systemd-255.2
#testdisk-7.1
#texinfo-interactive-7.0.3
#time-1.9
#tmux-3.4
#tree-2.1.1
#unrar-6.2.12
#unzip-6.0
#usbutils-017
#util-linux-2.39.3
#wget-1.21.4
#which-2.21
#xz-5.4.6
#yq-3.2.3
#zip-3.0
#zstd-1.5.
#
#    # Firmware
#    linux-firmware                # 
#    alsa-firmware                 #
#    
#    # Networking utilities
#    git                           # The fast distributed version control system
#    nfs-utils                     # Support programs for Network File Systems
#    wget                          # Retrieve files using HTTP, HTTPS, and FTP
#
#    # System utilities
#    efibootmgr                    # EFI Boot Manager
#    efivar                        # Tools to manipulate EFI variables
#    cdrtools                      # ISO tools e.g. isoinfo, mkisofs
#    ddrescue                      # GNU ddrescue, a data recovery tool
#    dos2unix                      # Text file format converter
#    #fwupd                         # Firmware update tool (NixOS requires building this?????)
#    gptfdisk                      # Disk tools e.g. sgdisk, gdisk, cgdisk
#    #'intel-ucode'               # required for Intel Microcode update files to boot
#    inxi                          # CLI system information tool
#    jq                            # Command line JSON processor, depof: kubectl
#    libisoburn                    # xorriso ISO creation tools
#    logrotate                     # Rotates and compresses system logs
#    nix-prefetch                  # Utility to fetch git source to compute hashes
#    #'mkinitcpio-vt-colors'      # vt-colors, mkintcpio, find, xargs, gawk, grep
#    psmisc                        # Proc filesystem utilities e.g. killall
#    smartmontools                 # Monitoring tools for hard drives
#    squashfsTools                 # mksquashfs, unsquashfs
#    testdisk                      # Checks and undeletes partitions + photorec
#    tmux                          # Terminal multiplexer
#    tree                          # Simple dir listing app in tree form
#    usbutils                      # Tools for working with USB devices e.g. lsusb
#    yq                            # Command line YAML/XML/TOML processor
#
#    # Compression utilities
#    p7zip                         # Comman-line file archiver for 7zip format, depof: thunar
#    unrar                         # Unfree utility to uncompress RAR archives
#    unzip                         # Uncompress Zip archives
#    zip                           # Create zip archives
#
#  ];
}
