# NixOS system configuration
#
# Inspiration:
# * [spikespaz](https://github.com/spikespaz/dotfiles/blob/odyssey/flake.nix)
# --------------------------------------------------------------------------------------------------
{
  description = "System Configuration";

  # ### inputs specifies other flakes to be used in the outputs as dependencies.
  # After inputs are resolved they are passed to the outputs function and map to the explicit and 
  # implicit arguments as defined by the outputs function.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11"; 
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable"; 

    # Note the master branch in home manager equates to unstable in nixos
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  # ### Implicit arguments
  # In nix function syntax we can require arguments by name explicitly as 'self' is below and using 
  # the '...' allow for additional implicit arguments that will be gathered into a set named 'NAME' 
  # with the '@NAME' syntax. Flake syntax specifies that once 'inputs' are resolved they are passed 
  # to the outputs function as arguments. Thus by naming the implicit arguments '@inputs' we are not 
  # referring to the original inputs attribute set but rather naming the implicit arguments to our 
  # function 'inputs' which happens to also be the name of a flakes inputs attribute set. In the end
  # it works out function the same but is a mistake to conflate the two for general nix cases.
  #
  # ### Explicit arguments
  # Although it is nice to gather all implicit arguments together this means to use them without the 
  # do notation would require an 'inherit (inputs) nixpkgs' to bring them into scope. Another option 
  # is to just call them out explicitly as required named arguments which does this scoping for you.
  outputs = { self, nixpkgs, home-manager, ... }@inputs: let

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
#    nixpkgs.config.allowUnfree = true;

#    pkgs = import inputs.nixpkgs {
#      system = systemSettings.system;
#      config.allowUnfree = true;
#      config.allowUnfreePredicate = _: true;
#    };
#
#    # Add the ability to access unstable packages
#    pkgs-unstable = import inputs.nixpkgs-unstable {
#      system = systemSettings.system;
#      config.allowUnfree = true;
#      config.allowUnfreePredicate = _: true;
#    };

    # Using attribute set update syntax '//' here to combine a couple sets for simpler input arguments
    lib = nixpkgs.lib // home-manager.lib;
    args = inputs // { inherit systemSettings homeSettings; };

    system = systemSettings.system;
    pkgs = nixpkgs.legacyPackages.${system};
    specialArgs = { inherit args; };
    extraSpecialArgs = { inherit args; };
    baseModules = [
        #{ nixpkgs = { inherit pkgs; }; }
    ];

  # Pass along configuration variables defined above
  # * [Special Args](https://github.com/nix-community/home-manager/issues/1022)
  # ------------------------------------------------------------------------------------------------
  in {
    nixosConfigurations = {

      # Define system configuration for an installation
      # Note this 'install' value is used in place of the hostname target in most flakes
      install = lib.nixosSystem {
        inherit pkgs system specialArgs;

        # modules = base.modules ++ [ ];
        modules = [
          ./hardware-configuration.nix
          #(./. + "/profiles" + ("/" + systemSettings.profile + ".nix"))
          "${nixpkgs}/nixos/modules/profiles/headless.nix"
          "${nixpkgs}/nixos/modules/profiles/minimal.nix"
        ];
      };

      # Defines configuration for building an ISO
      # Starts from the minimal iso config and adds additional config
      iso = lib.nixosSystem {
        inherit pkgs system specialArgs;
        modules = [ ./profiles/base/iso.nix ];
      };
    };

#    homeConfigurations = {
#      iso = lib.homeManagerConfiguration {
#        inherit pkgs system extraSpecialArgs;
#        modules = [ ./home-manager/iso.nix ];
#      };
#    };
  };
}

# vim:set ts=2:sw=2:sts=2
