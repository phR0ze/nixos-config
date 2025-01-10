{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/3566ab7246670a43abd2ffa913cc62dad9cdf7d5";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/cf737e2eba82b603f54f71b10cb8fd09d22ce3f5";
    microvm.url = "github:astro/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-trusted-substituters = [ "https://cache.soopy.moe" ];
    extra-substituters = [ "https://cache.soopy.moe" ];
    extra-trusted-public-keys = [ "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo=" ];
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-hardware, microvm, ... }@inputs: let
    _args = import ./args.nix;

    # Allow for package patches, overrides and additions
    # ----------------------------------------------------------------------------------------------
    system = _args.arch;
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
    args = _args // (f.fromYAML ./args.dec.yaml) // {
      comment = f.gitMessage ./.;
    };
    specialArgs = { inherit args f inputs; };
  in
  {
    # Usually the configuration is the hostname of the machine but in this case I'm using a generic 
    # value as an entry point with the hostname being set lower down based on the configuration 
    # linked from the machine's sub-directory.
    # ----------------------------------------------------------------------------------------------
    nixosConfigurations.system = nixpkgs.lib.nixosSystem {
      inherit pkgs system specialArgs;
      modules = [
        microvm.nixosModules.host
        ./options
        ./configuration.nix
      ];
    };
  };
}
