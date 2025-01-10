{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/3566ab7246670a43abd2ffa913cc62dad9cdf7d5";
  inputs.nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.microvm.url = "github:astro/microvm.nix";
  inputs.microvm.inputs.nixpkgs.follows = "nixpkgs";

  nixConfig = {
    extra-substituters = [ "https://microvm.cachix.org" ];
    extra-trusted-public-keys = [ "microvm.cachix.org-1:oXnBc6hRE3eX5rSYdRyMYXnfzcCxC7yKPTbZXALsqys=" ];
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, microvm, ... }@inputs: let
    _args = import ./args.nix;

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
        #"freeimage-unstable-2021-11-01"
      ];
      overlays = [
        (before: after: {
          vscode = pkgs-unstable.vscode;
          rust-lang.rust-analyzer = pkgs-unstable.vscode-extensions.rust-lang.rust-analyzer;
          vadimcn.vscode-lldb = pkgs-unstable.vscode-extensions.vadimcn.vscode-lldb;
        })
      ];
    };

    # Configure special args with our argument overrides
    f = pkgs.callPackage ./options/funcs { lib = nixpkgs.lib; };
    args = _args // (f.fromYAML ./args.dec.yaml) // {
      comment = f.gitMessage ./.;
    };
    specialArgs = { inherit args f inputs; };
  in
  {
    nixosConfigurations.system = nixpkgs.lib.nixosSystem {
      inherit pkgs system specialArgs;
      modules = [
        microvm.nixosModules.microvm
        ./options
        ./configuration.nix
      ];
    };
  };
}
