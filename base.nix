{
  inputs = {
    # nixos-unstable from 2025.08.09
    nixpkgs.url = "github:nixos/nixpkgs/85dbfc7aaf52ecb755f87e577ddbe6dbbdbc1054";

    # nixos-unstable from 2025.08.31
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # nixos-unstable from 2024.12.13
    nixpkgs-rustdesk.url = "github:nixos/nixpkgs/3566ab7246670a43abd2ffa913cc62dad9cdf7d5";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-rustdesk, ... }@inputs: let
    _args = import ./args.nix;

    # Allow for package patches, overrides and additions
    # ----------------------------------------------------------------------------------------------
    system = _args.arch;
    pkgs-rustdesk = import nixpkgs-rustdesk { inherit system; };
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfreePredicate = pkg: true;
      config.android_sdk.accept_license = true;
      config.nvidia.acceptLicense = true;
    };
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfreePredicate = pkg: true;
      config.android_sdk.accept_license = true;
      config.nvidia.acceptLicense = true;
      #config.permittedInsecurePackages = [
        #"freeimage-3.18.0-unstable-2024-04-18"     # Allowing this for wii tools
      #];

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

          # Override packages with other versions:
          immich = pkgs-unstable.immich;
          vscode = pkgs-unstable.vscode;
          zed-editor = pkgs-unstable.zed-editor;
          zoom-us = pkgs-unstable.zoom-us;
          rust-analyzer = pkgs-unstable.rust-analyzer;
          rust-lang.rust-analyzer = pkgs-unstable.vscode-extensions.rust-lang.rust-analyzer;
          vadimcn.vscode-lldb = pkgs-unstable.vscode-extensions.vadimcn.vscode-lldb;
          yt-dlp = pkgs-unstable.yt-dlp;

          # RustDesk is failing with the display dummy plug
          #rustdesk-flutter = pkgs-rustdesk.rustdesk-flutter;
        })
      ];
    };

    # Configure special args with our argument overrides
    # ----------------------------------------------------------------------------------------------
    lib = nixpkgs.lib;
    f = pkgs.callPackage ./funcs {};
    args = lib.recursiveUpdate _args (let
      baseArgsFile = ./args.dec.json;
      machineArgsFile = ./machines/${_args.hostname}/args.dec.json;
      baseArgs = if builtins.pathExists baseArgsFile then f.fromJSON baseArgsFile else {};
      machineArgs = if builtins.pathExists machineArgsFile then f.fromJSON machineArgsFile else {};
      in lib.recursiveUpdate baseArgs (let
        installArgs = if builtins.pathExists ./install.nix then (import ./install.nix) else {};
        in lib.recursiveUpdate machineArgs installArgs
      )
    );
  in
  {
    # Usually the configuration is the hostname of the machine but in this case I'm using a generic 
    # value 'target' as an entry point with the hostname being set lower down based on the 
    # configuration linked from the machine's sub-directory.
    # ----------------------------------------------------------------------------------------------
    nixosConfigurations.target = lib.nixosSystem {
      inherit pkgs system; specialArgs = { inherit args f inputs; };
      modules = [ ./options ./configuration.nix ];
    };

    # Generic install host configuration based on a generic profile
    nixosConfigurations.install = lib.nixosSystem {
      inherit pkgs system; specialArgs = { inherit args f inputs; };
      modules = [ ./hardware-configuration.nix (./. + "/" + args.target) ];
    };

    # Defines configuration for building an ISO
    # - specialArgs is being carefully constructed to exclude secrets
    # - re-using the profiles/install.nix to set defaults otherwise set in secrets
    # ----------------------------------------------------------------------------------------------
    nixosConfigurations.iso = lib.nixosSystem {
      inherit pkgs system;
      specialArgs = {
        inherit f inputs;
        args = lib.recursiveUpdate _args (import ./profiles/install.nix);
      };
      modules = [ ./options ./profiles/iso.nix ];
    };
  };
}
