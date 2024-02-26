# Minimal bootable configuration
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
    ../../system/boot/initrd.nix
    ../../system/locale.nix
    ../../system/shell/bash.nix
    ../../system/users.nix
    ../../system/security/sudo.nix
    ../../system/services/sshd.nix
    ../../system/nix.nix
    ../../system/networking/base.nix
  ];

  # Bootable systems imply a more general use case. Overriding the minimal.nix to include
  # docs and basic services; however this adds a full 500 MiB to the installation.
  documentation.enable = lib.mkOverride 500 true;
  documentation.doc.enable = lib.mkOverride 500 true;
  documentation.info.enable = lib.mkOverride 500 true;
  documentation.man.enable = lib.mkOverride 500 true;
  documentation.nixos.enable = lib.mkOverride 500 true;

  # Set the NixOS version that this was installed with
  system.stateVersion = args.systemSettings.stateVersion;

  # Base system packages
  environment.systemPackages = with pkgs; [
#    pkgs.w3m-nographics # needed for the manual anyway
#    pkgs.testdisk # useful for repairing boot problems
#    pkgs.ms-sys # for writing Microsoft boot sectors / MBRs
#    pkgs.efibootmgr
#    pkgs.efivar
#    pkgs.parted
#    pkgs.gptfdisk
#    pkgs.ddrescue
#    pkgs.ccrypt
#    pkgs.cryptsetup # needed for dm-crypt volumes
    git                                      # Required for Flakes support

    # Some text editors.
    (vim.customize {
      name = "vim";
      vimrcConfig.packages.default = {
        start = [ pkgs.vimPlugins.vim-nix ];
      };
      vimrcConfig.customRC = "syntax on";
    })

#    # Some networking tools.
#    pkgs.fuse
#    pkgs.fuse3
#    pkgs.sshfs-fuse
#    pkgs.socat
#    pkgs.screen
#    pkgs.tcpdump
#
#    # Hardware-related tools.
#    pkgs.sdparm
#    pkgs.hdparm
#    pkgs.smartmontools # for diagnosing hard disks
#    pkgs.pciutils
#    pkgs.usbutils
#    pkgs.nvme-cli
#
#    # Some compression/archiver tools.
#    pkgs.unzip
#    pkgs.zip
  ];
}

# vim:set ts=2:sw=2:sts=2
