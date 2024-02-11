# NixOS system configuration
#
# Inspiration:
# * [spikespaz](https://github.com/spikespaz/dotfiles/blob/odyssey/flake.nix)
# --------------------------------------------------------------------------------------------------
{
  description = "System Configuration";

  inputs = {
    # Call out the https://github.com/NixOS/nixpkgs branches to use
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; 
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11"; 
  };

  outputs = { self, nixpkgs, nixpkgs-stable, ... }@inputs:
  let
    # System install settings
    # ----------------------------------------------------------------------------------------------
    systemSettings = {
      stateVersion = "23.11";

      # Configuration overriden by user selections in the clu installer
      hostname = "nixos";             # hostname to use for the install
      hardware = [ ];                 # pre-defined configuration for specific hardware in './hardware'
      username = "nixos";             # initial admin user to create during install
      userpass = "nixos";             # admin user password securely entered during boot
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
      #wmType = if (wm == "hyprland") then "wayland" else "x11";
      term = "alacritty";             # default terminal to use
      fontName = "Intel One Mono";    # default font name
      #fontPkg = pkgs.intel-one-mono;  # default font package
      editor = "nvim";                # default editor
    };

    # Allow for package patches, overrides and additions
    # * [allowUnfree](https://nixos.wiki/wiki/Unfree_Software)
    # * [lookup-paths](https://nix.dev/tutorials/nix-language.html#lookup-paths)
    # * [Override nixpkgs](https://discourse.nixos.org/t/allowunfree-predicate-does-not-apply-to-self-packages/21734/6)
    # ----------------------------------------------------------------------------------------------
    system = systemSettings.system;
    stateVersion = systemSettings.stateVersion;
#    pkgs = import nixpkgs {
#      inherit system;
#      config.allowUnfree = true;
#      config.allowUnfreePredicate = _: true;
#    };
#
#    # Preserve the ability to access stable packages
#    pkgs-stable = import nixpkgs-stable {
#      inherit system;
#      config.allowUnfree = true;
#      config.allowUnfreePredicate = _: true;
#    };
#lib = nixpkgs.lib;

  # Pass along configuration variables defined above
  # * [Special Args](https://github.com/nix-community/home-manager/issues/1022)
  # ------------------------------------------------------------------------------------------------
  in {

    # Define default system configuration
    # Note this 'default' value is used in place of the hostname target in most flakes
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      inherit system;

      # Pass along config variables defined above
      specialArgs = {
        #inherit pkgs-stable;
        inherit systemSettings;
        inherit homeSettings;
      };

      # Load configuration modules and use the modified pkgs
      modules = [
#          {
#            nixpkgs = {
#              inherit pkgs;
#            };
#          }
        ./hardware-configuration.nix
        (./. + "/profiles" + ("/" + systemSettings.profile + ".nix"))
      ];
    };
  };
}

# vim:set ts=2:sw=2:sts=2
