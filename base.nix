{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/3566ab7246670a43abd2ffa913cc62dad9cdf7d5";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... }@inputs: let
    _args = import ./args.nix;

    # Allow for package patches, overrides and additions
    # ----------------------------------------------------------------------------------------------
    system = _args.arch;
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfreePredicate = pkg: true;
      config.android_sdk.accept_license = true;
    };
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfreePredicate = pkg: true;
      config.android_sdk.accept_license = true;
      config.permittedInsecurePackages = [
        "freeimage-unstable-2021-11-01"     # Allowing this for wii tools
      ];

      # Modify package defaults with overlays
      # --------------------------------------------------------------------------------------------
      overlays = [
        (before: after: {
          # Include custom packages in global pkgs variable
          arcologout = pkgs.callPackage packages/arcologout {};
          desktop-assets = pkgs.callPackage packages/desktop-assets {};
          rdutil = pkgs.callPackage packages/rdutil {};
          tinymediamanager = pkgs.callPackage packages/tinymediamanager{};
          wmctl = pkgs.callPackage packages/wmctl {};

          # Upgrade select packages to the latest unstable bits
          go = pkgs-unstable.go;
          go-bindata = pkgs-unstable.go-bindata;
          golangci-lint = pkgs-unstable.golangci-lint;
          vscode = pkgs-unstable.vscode;
          zed-editor = pkgs-unstable.vscode;
          zoom-us = pkgs-unstable.zoom-us;
          rustdesk-flutter = pkgs-unstable.rustdesk-flutter;
          rust-lang.rust-analyzer = pkgs-unstable.vscode-extensions.rust-lang.rust-analyzer;
          vadimcn.vscode-lldb = pkgs-unstable.vscode-extensions.vadimcn.vscode-lldb;
        })
      ];
    };

    # Configure special args with our argument overrides
    # ----------------------------------------------------------------------------------------------
    lib = nixpkgs.lib;
    f = pkgs.callPackage ./options/funcs { inherit lib; };
    args = lib.recursiveUpdate (lib.recursiveUpdate _args (f.fromJSON ./args.dec.json))
      (f.fromJSON ./machines/${_args.hostname}/args.dec.json);
    specialArgs = { inherit args f inputs; };
  in
  {
    # Usually the configuration is the hostname of the machine but in this case I'm using a generic 
    # value 'target' as an entry point with the hostname being set lower down based on the 
    # configuration linked from the machine's sub-directory.
    # ----------------------------------------------------------------------------------------------
    nixosConfigurations.target = lib.nixosSystem {
      inherit pkgs system specialArgs;
      modules = [ ./options ./configuration.nix ];
    };

    # Generic install host configuration based on a generic profile
    nixosConfigurations.install = lib.nixosSystem {
      inherit pkgs system specialArgs;
      modules = [
        ./hardware-configuration.nix
        (./. + "/profiles" + ("/" + args.profile + ".nix"))
      ];
    };

    # Defines configuration for building an ISO
    # ----------------------------------------------------------------------------------------------
    nixosConfigurations.iso = lib.nixosSystem {
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
