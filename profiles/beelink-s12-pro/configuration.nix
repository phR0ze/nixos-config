# cyberlinux configuration file
# --------------------------------------------------------------------------------------------------
# References
# * [NixOS config collection](https://nixos.wiki/wiki/Configuration_Collection)
# * [Modular example](https://github.com/mogria/nixos-config)
# --------------------------------------------------------------------------------------------------
# Show all install packages:
# nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq
# --------------------------------------------------------------------------------------------------
# https://github.com/ilya-fedin/nixos-configuration/blob/master/configuration.nix
#
# 1. make changes as needed
# 2. sudo nixos-rebuild switch
# --------------------------------------------------------------------------------------------------

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.pcrumm = {
    isNormalUser = true;
    extraGroups = [
      "wheel"                   # enables passwordless sudo for this user
      "networkmanager"          # enables ability for user to make network manager changes
    ];
    initialPassword = "nixos";  # temp password to change on first login
  };

  # Set your time zone
  # ------------------------------------------------------------------------------------------------
  time.timeZone = "America/Boise";

  # Boot loader
  # ------------------------------------------------------------------------------------------------
  boot.loader = {
    grub.enable = true;

    # Configure EFI boot support using standard EFI/BOOT/BOOTX64.efi for most versatile compatibility.
    efi.efiSysMountPoint = "/boot";
    grub.efiSupport = true;
    grub.efiInstallAsRemovable = true; # i.e. EFI/BOOT/BOOTX64.efi
    grub.device = "nodev"; # to avoid MBR BIOS and only install EFI

    # Configure BIOS MBR boot support 
    # grub.device = "/dev/sda";
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Networking
  # NixOS uses DHCP by default to automatically configure the interface
  # ------------------------------------------------------------------------------------------------
  networking = {
    hostName = "beelink8";                  # define hostname
    enableIPv6 = false;                     # disable IPv6
    nameservers = [ "1.1.1.1" "1.0.0.1" ];  # use the Cloudflare DNS
    networkmanager.enable = true;           # easiest way to get networking up and runnning
    # wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  };

  # Hardware configuration
  # ------------------------------------------------------------------------------------------------
  sound.enable = true;
  # sound.enableMediaKeys = true;
  hardware.pulseaudio.enable = true;

  # Setup sudo configuration
  security.sudo = {
    enable = true;
    extraRules = [
      # Configure passwordless sudo access for 'wheel' group
      { commands = [{ command = "ALL"; options = [ "NOPASSWD" ];}]; groups = [ "wheel" ]; }
    ];
  };

  # List services that you want to enable:
  # https://nixos.org/manual/nixos/stable/options#opt-services.openssh.enable
  # ------------------------------------------------------------------------------------------------
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };

  # Enable the Desktop Environment
  # ------------------------------------------------------------------------------------------------
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    desktopManager = {
      xfce.enable = true;
      xfce.enableXfwm = true;
      xterm.enable = false;
    };
    displayManager = {
      defaultSession = "xfce";
      autoLogin.enable = true;
      autoLogin.user = "pcrumm";
    };
  };

  # NFS Shares
  # ------------------------------------------------------------------------------------------------
  services.rpcbind.enable = true; # needed for NFS
  fileSystems = {
    "/mnt/Movies" = {
      device = "192.168.1.2:/srv/nfs/Movies";
      fsType = "nfs";
      options = [ "auto" "noacl" "noatime" "nodiratime" "rsize=8192" "wsize=8192" "timeo=15" "_netdev" ];
    };
    "/mnt/Kids" = {
      device = "192.168.1.2:/srv/nfs/Kids";
      fsType = "nfs";
      options = [ "auto" "noacl" "noatime" "nodiratime" "rsize=8192" "wsize=8192" "timeo=15" "_netdev" ];
    };
    "/mnt/TV" = {
      device = "192.168.1.2:/srv/nfs/TV";
      fsType = "nfs";
      options = [ "auto" "noacl" "noatime" "nodiratime" "rsize=8192" "wsize=8192" "timeo=15" "_netdev" ];
    };
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
 
  # Environment configs
  # ------------------------------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    inxi
    libva-utils
    mpv
    nfs-utils
    kodi
    firefox
    vim
    wget
  ];

  # Original NixOS you installed from
  # Used for compatibility etc... and shouldn't ever be changed
  system.stateVersion = "23.11";
}

# vim:set ts=2:sw=2:sts=2
