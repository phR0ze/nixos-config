# NixOS system configuration
# --------------------------------------------------------------------------------------------------
{
  description = "System Configuration";

  # ### inputs specifies other flakes to be used in the outputs as dependencies.
  # After inputs are resolved they are passed to the outputs function and map to the explicit and 
  # implicit arguments as defined by the outputs function.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/1536926ef5621b09bba54035ae2bb6d806d72ac8";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
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
  # dot notation would require an 'inherit (inputs) nixpkgs' to bring them into scope. Another option 
  # is to just call them out explicitly as required named arguments which does this scoping for you.
  outputs = { self, nixpkgs, nixpkgs-unstable, ... }@inputs: let

    # Configurable system options
    # ----------------------------------------------------------------------------------------------
    settings = {
      stateVersion = "24.05";           # Base install version, not sure this matters when on flake
    }
    // import ./flake_private.nix;      # include external configuration set

    # Allow for package patches, overrides and additions
    # * [allowUnfree](https://nixos.wiki/wiki/Unfree_Software)
    # * [lookup-paths](https://nix.dev/tutorials/nix-language.html#lookup-paths)
    # * [Override nixpkgs](https://discourse.nixos.org/t/allowunfree-predicate-does-not-apply-to-self-packages/21734/6)
    # ----------------------------------------------------------------------------------------------
    pkgs-unstable = import nixpkgs-unstable {
      system = settings.system;
      config.allowUnfree = true;
      config.allowUnfreePredicate = _: true;
    };

    pkgs = import nixpkgs {
      system = settings.system;
      config.allowUnfree = true;
      config.allowUnfreePredicate = _: true;
      config.permittedInsecurePackages = [
        # Allowing this for wii tools
        "freeimage-unstable-2021-11-01"
        #"qtwebkit-5.212.0-alpha4"
      ];

      # Modify the set of packages to be used for installs
      # --------------------------------------------------------------------------------------------
      # 'self' is the set of packages before any modifications
      # 'super' is the super set of packages after being modified
      overlays = [

        # Upgrade select packages to the latest unstable bits
        (self: super: {
          go = pkgs-unstable.go;
          go-bindata = pkgs-unstable.go-bindata;
          golangci-lint = pkgs-unstable.golangci-lint;
          vscode = pkgs-unstable.vscode;
          zed-editor = pkgs-unstable.vscode;
          rust-lang.rust-analyzer = pkgs-unstable.vscode-extensions.rust-lang.rust-analyzer;
          vadimcn.vscode-lldb = pkgs-unstable.vscode-extensions.vadimcn.vscode-lldb;
        })
      ];
    };

    # Import all custom functions to be use throughout
    f = pkgs.callPackage ./options/funcs.nix { lib = nixpkgs.lib; };
    args = inputs // { inherit settings; } // {
      iso = false;
      userHome = "/home/${settings.username}";
      configHome = "/home/${settings.username}/.config";
    };
    system = settings.system;
    specialArgs = { inherit args f; };
    
  in {
    # These are the configurations for different use cases a.k.a. systems
    nixosConfigurations = {

      # Defines configuration for the current system
      system = nixpkgs.lib.nixosSystem {
        inherit pkgs system specialArgs;
        modules = [
          ./options
          ./hardware-configuration.nix
          (./. + "/profiles" + ("/" + settings.profile + ".nix"))
        ];
      };

      # Defines configuration for the test vm
      vm = nixpkgs.lib.nixosSystem {
        inherit pkgs system specialArgs;
        modules = [
          ./options
          (./. + "/profiles" + ("/" + settings.profile + ".nix"))
          ({
            virtualisation.vmVariant = {
              # nixpkgs/nixos/modules/virtualisation/qemu-vm.nix
              virtualisation = {
                cores = 4;
                diskSize = 20 * 1024;   # 20 GB
                memorySize = 4 * 1024;  # 4 GB
                resolution = { x = 1920; y = 1080; };

                # Allows for sftp, ssh etc... to the guest via localhost:2222
                forwardPorts = [ { from = "host"; host.port = 2222; guest.port = 22; } ];
              };
            };
          })
        ];
      };

      # Defines configuration for building an ISO
      iso = nixpkgs.lib.nixosSystem {
        inherit pkgs system;
        # Update the args.iso field to be true and set username for ISO builds
        specialArgs = specialArgs // {
          args = args // {
            iso = true;
            settings = settings // {
              username = "nixos";
              autologin = true;
            };
          };
        };
        modules = [
          ./options
          ./profiles/iso/default.nix
        ];
      };
    };
  };
}
