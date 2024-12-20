{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/1536926ef5621b09bba54035ae2bb6d806d72ac8";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... }@inputs: let
    _flake_args = import ./flake_args.nix;

    # Allow for package patches, overrides and additions
    # ----------------------------------------------------------------------------------------------
    system = _flake_args.system;
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
      config.allowUnfreePredicate = _: true;
    };
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.allowUnfreePredicate = _: true;
      config.permittedInsecurePackages = [
        "freeimage-unstable-2021-11-01"     # Allowing this for wii tools
      ];

      # Modify package defaults with overlays
      # --------------------------------------------------------------------------------------------
      overlays = [

        # Upgrade select packages to the latest unstable bits
        (before: after: {
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

    # Configure special args with our argument overrides
    # ----------------------------------------------------------------------------------------------
    f = pkgs.callPackage ./options/funcs { lib = nixpkgs.lib; };
    _private_args = f.fromYAML ./args.dec.yaml;
    _private_flake_args = f.fromYAML ./flake_args.dec.yaml;
    _args = _flake_args // (import ./args.nix) // _private_flake_args // _private_args;

    # order of merging precedence is important for overrides
    args = _args // inputs // {
      isVM = false;
      isISO = false;
      #comment = pkgs.callPackage ./options/funcs/git-message.nix { path = ./.; };
      comment = f.gitMessage ./.;
      userHome = "/home/${_args.username}";
      configHome = "/home/${_args.username}/.config";
    };
    specialArgs = { inherit args f; };
  in
  {
    # Local system configuration, usually the hostname of the machine, but using this in a way to 
    # make it reusable for all my machines via links in the root of the repo.
    # ----------------------------------------------------------------------------------------------
    nixosConfigurations.system = nixpkgs.lib.nixosSystem {
      inherit pkgs system specialArgs;
      modules = [ ./options ./configuration.nix ];
    };

    # Generic install host configuration based on a generic profile
    nixosConfigurations.install = nixpkgs.lib.nixosSystem {
      inherit pkgs system specialArgs;
      modules = [
        ./hardware-configuration.nix
        (./. + "/profiles" + ("/" + args.profile + ".nix"))
      ];
    };

    # Defines configuration for the test vm
    # ----------------------------------------------------------------------------------------------
    nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
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
      modules = [ ./options ./profiles/vm/default.nix ];
    };

    # Defines configuration for building an ISO
    # ----------------------------------------------------------------------------------------------
    nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
      inherit pkgs system;
      specialArgs = specialArgs // {
        args = args // {
          isIso = true;
          username = "nixos";
          autologin = true;
        };
      };
      modules = [ ./options ./profiles/iso/default.nix ];
    };
  };
}
