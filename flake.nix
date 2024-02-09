{
  description = "System Configuration";

  inputs = {
    # Call out the https://github.com/NixOS/nixpkgs branches to use
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; 
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11"; 
  };

  let
    # User configurable install settings
    # ----------------------------------------------------------------------------------------------
    installSettings = {
      system = "x86_64-linux";        # system architecture to use
      hostname = "nixos";             # hostname to use for the install
      profile = "theater";            # pre-defined configurations in path './profiles' selection
      hardware = [ ];                 # pre-defined configuration for specific hardware in './hardware'
      timezone = "America/Boise";     # time-zone selection
      locale = "en_US.UTF-8";         # locale selection
      user = "nixos";                 # initial admin user to create during install
      name = "nixos";                 # name to use for git and other app configurations
      email = "nixos@nixos.org";      # email to use for git and other app configurations          

    };

    # User selected tooling and environment settings
    # ----------------------------------------------------------------------------------------------
    envSettings = {
      wmType = if (wm == "hyprland") then "wayland" else "x11";
      term = "alacritty";             # default terminal to use
      fontName = "Intel One Mono";    # default font name
      fontPkg = pkgs.intel-one-mono;  # default font package
      editor = "nvim";                # default editor
    };

  outputs = { self, nixpkgs }: {
    # Default hostname 'nixos' below is the main entry point for configuration
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix

        # Ultra minimal system
        {
          imports = [
            <nixpkgs/nixos/modules/profiles/minimal.nix>
          ];
          boot.loader = {
            grub.enable = true;
            efi.efiSysMountPoint = "/boot";
            grub.efiSupport = true;
            grub.efiInstallAsRemovable = true; # i.e. EFI/BOOT/BOOTX64.efi
            grub.device = "nodev"; # to avoid MBR BIOS and only install EFI
          };
          system.stateVersion = "23.11";
        }
      ];
    };
  };
}

# vim:set ts=2:sw=2:sts=2
