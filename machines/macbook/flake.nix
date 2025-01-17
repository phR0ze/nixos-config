{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/3566ab7246670a43abd2ffa913cc62dad9cdf7d5";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/cf737e2eba82b603f54f71b10cb8fd09d22ce3f5";
  };

  nixConfig = {
    extra-trusted-substituters = [ "https://cache.soopy.moe" ];
    extra-substituters = [ "https://cache.soopy.moe" ];
    extra-trusted-public-keys = [ "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo=" ];
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-hardware, ... }@inputs: let
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
        "freeimage-unstable-2021-11-01"     # Allowing this for wii tools
      ];

      # Modify package defaults with overlays
      overlays = [
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
    f = pkgs.callPackage ./options/funcs { lib = nixpkgs.lib; };
    args = _args // (f.fromYAML ./args.dec.yaml) // {
      comment = f.gitMessage ./.;
    };
    specialArgs = { inherit args f inputs; };
  in
  {
    nixosConfigurations.target = nixpkgs.lib.nixosSystem {
      inherit pkgs system specialArgs;
      modules = [
        ./options
        ./configuration.nix
      ];
    };
  };
}
