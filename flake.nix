{
  description = "System Configuration";

  # ### inputs specifies other flakes to be used in the outputs as dependencies.
  # After inputs are downloaded and cached they are passed to the outputs function and map to the 
  # explicit and implicit arguments as defined by the outputs function.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/1536926ef5621b09bba54035ae2bb6d806d72ac8";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... }@inputs: let

    # Configurable system options
    # ----------------------------------------------------------------------------------------------
    settings = (import ./flake_private.nix);      # include external configuration set

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

    # Combine all input args, custom function and types together in special args
    # ----------------------------------------------------------------------------------------------
    f = pkgs.callPackage ./options/funcs.nix { lib = nixpkgs.lib; };
    args = inputs // settings // {
      isVM = false;
      isISO = false;
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
          (./. + "/profiles" + ("/" + args.profile + ".nix"))
        ];
      };

      # Defines configuration for the test vm
      vm = nixpkgs.lib.nixosSystem {
        inherit pkgs system;
        specialArgs = specialArgs // {
          args = args // {
            isVM = true;
            autologin = true;
            nic0 = "eth0";                # Nic override for vm
            cores = 4;                    # Cores to use
            diskSize = 1;                 # Disk size in GiB
            memorySize = 4;               # Memory size in GiB
            resolution.x = 1920;          # Resolution x dimension
            resolution.y = 1080;          # Resolution y dimension
          };
        };
        modules = [
          ./options
          ./profiles/vm/default.nix
        ];
      };

      # Defines configuration for building an ISO
      iso = nixpkgs.lib.nixosSystem {
        inherit pkgs system;
        specialArgs = specialArgs // {
          args = args // {
            isIso = true;
            username = "nixos";
            autologin = true;
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
