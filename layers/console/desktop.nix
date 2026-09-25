# desktop.nix provides a minimal shell environment fit for a desktop console experience
# - anything fit for a console that doesn't require a windowing system should belong here
#
# ### Dependencies
# - `server` gets configured with passed along options
#
# ### Features
# - Kernel custom configuration
# - Passwordless access for Sudo for default user
# - SSHD custom configuration
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, ... }:
let
  cfg = config.layers.console.desktop;
in
{
  options = {
    layers.console.desktop = {
      enable = lib.mkEnableOption "Enable the desktop layer";
      harden = lib.mkEnableOption "Enable security hardening configuration";
      lowMemory = lib.mkEnableOption "Enable the low memory configuration";
    };
  };

  config = lib.mkMerge [

    (lib.mkIf (cfg.enable) {

      # Server dependencies with passed along configuration
      layers.console.server = {
        enable = true;
        harden = lib.mkIf cfg.harden true;
        lowMemory = lib.mkIf cfg.lowMemory true;
      };

      # Enable the desktop related settings
      devices.kernel.desktop = true;

      environment.systemPackages = with pkgs; [
        nfs-utils                      # Support programs for Network File Systems
        wget                          # Retrieve files using HTTP, HTTPS, and FTP

        # System utilities
        cdrtools                     # ISO tools e.g. isoinfo, mkisofs
        ddrescue                        # GNU ddrescue, a data recovery tool
        dos2unix                       # Text file format converter
        #fwupd                                # Firmware update tool (NixOS requires building this?????)
        gptfdisk                      # Disk tools e.g. sgdisk, gdisk, cgdisk
        #'intel-ucode'                        # required for Intel Microcode update files to boot
        inxi                        # CLI system information tool
        libisoburn                # xorriso ISO creation tools
        nix-prefetch                   # Utility to fetch git source to compute hashes
        nix-tree                       # Interactively browse Nix store path dependenices in the terminal
        #'mkinitcpio-vt-colors'               # vt-colors, mkintcpio, find, xargs, gawk, grep
        smartmontools                    # Monitoring tools for hard drives
        squashfsTools                  # mksquashfs, unsquashfs
        testdisk                         # Checks and undeletes partitions + photorec
        usbutils                         # Tools for working with USB devices e.g. lsusb

        # Compression utilities
        p7zip                          # Comman-line file archiver for 7zip format, depof: thunar
        unrar                          # Unfree utility to uncompress RAR archives
        unzip                            # Uncompress Zip archives
        zip                              # Create zip archives

        # Network
        dnsutils                     # DNS lookup tools e.g. dig, nslookup
        iw                              # nl80211 based CLI configuration utility for wireless devices
        net-tools                       # hostname, ifconfig, netstat, route
        openvpn                       # An easy-to-use, robust and highly configurable VPN (Virtual Private Network)
        update-systemd-resolved        # OpenVPN systemd-resolved updater
      ];
    })
  ];
}
