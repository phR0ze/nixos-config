{
  inputs = {
    # nixos-unstable from 2026.03.24
    nixpkgs.url = "github:nixos/nixpkgs/46db2e09e1d3f113a13c0d7b81e2f221c63b8ce9";

    # nixos-unstable from 2026.03.24
    nixpkgs-unstable.url = "github:nixos/nixpkgs/46db2e09e1d3f113a13c0d7b81e2f221c63b8ce9";

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
      config.nvidia.acceptLicense = true;
    };
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfreePredicate = pkg: true;
      config.android_sdk.accept_license = true;
      config.nvidia.acceptLicense = true;
      config.permittedInsecurePackages = [
        "broadcom-sta-6.30.223.271-57-6.12.41"      # Required for HP Notebook 15-AF123CL
        #"freeimage-3.18.0-unstable-2024-04-18"     # Allowing this for wii tools
      ];

      # Modify package defaults with overlays
      # --------------------------------------------------------------------------------------------
      overlays = [
        (before: after: {
          # Include custom packages in global pkgs variable to make them available throughout my
          # codebase rather than having to call them with a full path. Note I'm using package.nix
          # rather than default.nix as default.nix will be used for options.
          clu = pkgs.callPackage options/apps/system/clu/package.nix { src = self; };
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
          synology-drive-client = pkgs-unstable.synology-drive-client;
          tailscale = pkgs-unstable.tailscale;
          vadimcn.vscode-lldb = pkgs-unstable.vscode-extensions.vadimcn.vscode-lldb;
          yt-dlp = pkgs-unstable.yt-dlp;
        })
      ];
    };

    # Configure special args with our argument overrides
    # ----------------------------------------------------------------------------------------------
    lib = nixpkgs.lib;
    f = pkgs.callPackage ./funcs {};
    args = lib.recursiveUpdate _args (let
      baseArgsFile = ./args.dec.json;
      machineArgsFile = ./machines/${_args.hostname}/args.nix;
      machineDecArgsFile = ./machines/${_args.hostname}/args.dec.json;
      baseArgs = if builtins.pathExists baseArgsFile then f.fromJSON baseArgsFile else {};
      machineArgs = if builtins.pathExists machineArgsFile then (import machineArgsFile) else {};
      machineDecArgs = if builtins.pathExists machineDecArgsFile then f.fromJSON machineDecArgsFile else {};
      in lib.recursiveUpdate baseArgs (lib.recursiveUpdate machineArgs machineDecArgs)
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
        args = lib.recursiveUpdate _args (import ./profiles/iso_args.nix);
      };
      modules = [ ./options ./profiles/iso.nix ];
    };
  };
}
