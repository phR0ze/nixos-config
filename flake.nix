{
  description = "System Configuration";

  inputs = {
    # Call out the https://github.com/NixOS/nixpkgs branches to use
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; 
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11"; 
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let {
    # System install settings
    # ----------------------------------------------------------------------------------------------
    systemSettings = {
      stateVersion = "23.11";

      # Configuration set user interaction
      hostname = "nixos";             # hostname to use for the install
      hardware = [ ];                 # pre-defined configuration for specific hardware in './hardware'
      user = "nixos";                 # initial admin user to create during install
      name = "nixos";                 # name to use for git and other app configurations
      email = "nixos@nixos.org";      # email to use for git and other app configurations          
      profile = "base/bootable-bash"; # pre-defined configurations in path './profiles' selection
      
      # Configuration set via automation
      efi = true;                     # system boot type
      device = "nodev";               # destination disk for install
      system = "x86_64-linux";        # system architecture to use
      timezone = "America/Boise";     # time-zone selection
      locale = "en_US.UTF-8";         # locale selection
    };

    # User selected tooling and environment settings
    # ----------------------------------------------------------------------------------------------
    homeSettings = {
      wmType = if (wm == "hyprland") then "wayland" else "x11";
      term = "alacritty";             # default terminal to use
      fontName = "Intel One Mono";    # default font name
      fontPkg = pkgs.intel-one-mono;  # default font package
      editor = "nvim";                # default editor
    };

    # Allow for package patches, overrides and additions
    # * [allowUnfree](https://nixos.wiki/wiki/Unfree_Software)
    # * [lookup-paths](https://nix.dev/tutorials/nix-language.html#lookup-paths)
    # ----------------------------------------------------------------------------------------------
    pkgs = import nixpkgs {
      system = systemSettings.system;
      config.allowUnfree = true;
      config.allowUnfreePredicate = _: true;
    };

    # Preserve the ability to access stable packages
    pkgs-stable = import nixpkgs-stable {
      system = systemSettings.system;
      config.allowUnfree = true;
      config.allowUnfreePredicate = _: true;
    };

    lib = nixpkgs.lib;
  }

  # Pass along configuration variables defined above
  # * [Special Args](https://github.com/nix-community/home-manager/issues/1022)
  # ------------------------------------------------------------------------------------------------
  in {
    nixosConfigurations = {
      system = lib.nixosSystem {
        system = systemSettings.system;
        stateVersion = systemSettings.stateVersion;
        modules = [ 
          ./hardware-configuration.nix
          ./. + "/profiles/" + systemSettings.profile + ".nix"
        ];

        # Pass along config variables defined above
        specialArgs = {
          inherit pkgs;
          inherit pkgs-stable;
          inherit systemSettings;
          inherit homeSettings;
        };
      };
    };
  }
}

# vim:set ts=2:sw=2:sts=2
