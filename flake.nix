{
  inputs = {
    # nixos-unstable from 2026.07.05
    nixpkgs.url = "github:nixos/nixpkgs/d407951447dcd00442e97087bf374aad70c04cea";

    # nixos-unstable from 2026.08.09 (bumped for vaultwarden 1.37.1, fixes WASM client crashes)
    nixpkgs-unstable.url = "github:nixos/nixpkgs/f13ff45afd1bb73e640eaa08a7066dbed07e3238";

    # Only macbook's configuration.nix uses this (apple-t2 module), declared unconditionally here
    # since flake inputs can't be conditional on which host is being built.
    nixos-hardware.url = "github:nixos/nixos-hardware/779c32a00155994c86cde8213a8dd4df139d4355";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nixos-files.url = "github:phR0ze/nixos-files";
    nixos-files.inputs.nixpkgs.follows = "nixpkgs";
    nixos-files.inputs.sops-nix.follows = "sops-nix";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-hardware, ... }@inputs: let
    _args = import ./args.nix;
    lib = nixpkgs.lib;

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
          vaultwarden = pkgs-unstable.vaultwarden;
          yt-dlp = pkgs-unstable.yt-dlp;
        })
      ];
    };

    f = pkgs.callPackage ./funcs {};

    # Compose the argument overrides for the given hostname
    # ----------------------------------------------------------------------------------------------
    # Layering (lowest to highest priority): root args.nix -> root args.dec.json ->
    # machines/<hostname>/args.nix -> machines/<hostname>/args.dec.json. `hostname` and
    # `git.comment` are then always set authoritatively so no per-machine file needs to declare
    # them: `hostname` is simply the machines/ directory name being built, and `git.comment` comes
    # straight from flake introspection (self.rev), not a value written into a tracked file.
    mergeArgs = hostname: lib.recursiveUpdate (lib.recursiveUpdate _args (let
      baseArgsFile = ./args.dec.json;
      machineArgsFile = ./machines/${hostname}/args.nix;
      machineDecArgsFile = ./machines/${hostname}/args.dec.json;
      baseArgs = if builtins.pathExists baseArgsFile then f.fromJSON baseArgsFile else {};
      machineArgs = if builtins.pathExists machineArgsFile then (import machineArgsFile) else {};
      machineDecArgs = if builtins.pathExists machineDecArgsFile then f.fromJSON machineDecArgsFile else {};
      in lib.recursiveUpdate baseArgs (lib.recursiveUpdate machineArgs machineDecArgs)
    )) {
      hostname = hostname;
      git.comment = self.rev or "dirty";
    };

    # Used by the install/iso outputs, which have no per-host directory to derive a hostname or
    # comment from yet
    _bootstrapArgs = lib.recursiveUpdate _args { git.comment = self.rev or "dirty"; };

    # Every directory under ./machines is a real host
    machineNames = builtins.attrNames (lib.filterAttrs (n: v: v == "directory") (builtins.readDir ./machines));

    mkHost = hostname: lib.nixosSystem {
      inherit pkgs system;
      specialArgs = { inherit inputs f; args = mergeArgs hostname; };
      modules = [ inputs.nixos-files.nixosModules.default ./options (./machines + "/${hostname}/configuration.nix") ]
        ++ lib.optionals (hostname == "macbook") [ inputs.nixos-hardware.nixosModules.apple-t2 ];
    };
  in
  {
    # One real nixosConfigurations.<hostname> entry per machines/<hostname> directory. Since this
    # is a lazy attrset, evaluating `.#<hostname>` only forces that host's mkHost body - other
    # (still-encrypted) hosts' args are never touched.
    # ----------------------------------------------------------------------------------------------
    nixosConfigurations = lib.genAttrs machineNames mkHost // {

      # Generic install host configuration based on a generic profile, used to bootstrap a brand
      # new machine before it has its own machines/<hostname> directory.
      # --------------------------------------------------------------------------------------------
      install = lib.nixosSystem {
        inherit pkgs system; specialArgs = { inherit inputs f; args = _bootstrapArgs; };
        modules = [ ./hardware-configuration.nix (./. + "/" + _args.target) ];
      };

      # Defines configuration for building an ISO
      # - specialArgs is being carefully constructed to exclude secrets
      # - re-using the profiles/install.nix to set defaults otherwise set in secrets
      # --------------------------------------------------------------------------------------------
      iso = lib.nixosSystem {
        inherit pkgs system;
        specialArgs = {
          inherit f inputs;
          args = lib.recursiveUpdate _bootstrapArgs (import ./profiles/iso_args.nix);
        };
        modules = [ inputs.nixos-files.nixosModules.default ./options ./profiles/iso.nix ];
      };
    };
  };
}
