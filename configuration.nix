# configuration file
# --------------------------------------------------------------------------------------------------
# 1. Change directory `cd /etc/nixos`
# 2. Make changes as desired
# 3. Apply changes: `sudo nixos-rebuild switch --flake /path/to/my-flake#my-machine`
# --------------------------------------------------------------------------------------------------

{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix  # Include the results of the local hardware scan.
  ];

  # Nix system components configuration
  # ------------------------------------------------------------------------------------------------
  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ]; # enable flake support
  };
  nixpkgs = {
    config.allowUnfree = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nixos = {
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

  # Configure internationalization properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Networking
  # NixOS uses DHCP by default to automatically configure the interface
  # ------------------------------------------------------------------------------------------------
  networking = {
    hostName = "nixos";                     # define hostname
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
      xterm.enable = false;
    };
    displayManager.defaultSession = "xfce";
  };

  # Install system packages
  # ------------------------------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
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
