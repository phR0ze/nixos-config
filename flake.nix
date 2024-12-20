{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/1536926ef5621b09bba54035ae2bb6d806d72ac8";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... }@inputs: let
    args = (import ./flake_args.nix);
    args = args // {
      isVM = false;
      isISO = false;
      userHome = "/home/${args.username}";
      configHome = "/home/${args.username}/.config";
    };

    # Allow for package patches, overrides and additions
    system = args.system;
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

      # Modify packages: 'self' is before and 'super' is after
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

    f = pkgs.callPackage ./options/funcs.nix { lib = nixpkgs.lib; };
    specialArgs = { inherit args inputs f; };
  in
  {
    nixosConfigurations.homelab = nixpkgs.lib.nixosSystem {
      inherit pkgs system specialArgs;
      modules = [ ./options ./machines/homelab/hardware-configuration.nix ];
    };

    # Generic host configuration based on a generic profile
    nixosConfigurations.generic = nixpkgs.lib.nixosSystem {
      inherit pkgs system specialArgs;
      modules = [
        ./options
        ./hardware-configuration.nix
        (./. + "/profiles" + ("/" + args.profile + ".nix"))
      ];
    };

    # Defines configuration for the test vm
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
