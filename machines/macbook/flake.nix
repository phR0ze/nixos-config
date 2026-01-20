{
  inputs = {
    # nixos-unstable from 2025.08.09
    nixpkgs.url = "github:nixos/nixpkgs/85dbfc7aaf52ecb755f87e577ddbe6dbbdbc1054";

    # nixos-unstable from 2025.08.31
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Using [build on 2025.08.12 with 6.12.41 patches](https://hydra.soopy.moe/build/537#tabs-buildinputs)
    # - this build actually directly refers to "github:nixos/nixpkgs/85dbfc7aaf52ecb755f87e577ddbe6dbbdbc1054"
    nixos-hardware.url = "github:nixos/nixos-hardware/26ed7a0d4b8741fe1ef1ee6fa64453ca056ce113";
  };

  nixConfig = {
    extra-trusted-substituters = [ "https://cache.soopy.moe" ];
    extra-trusted-public-keys = [ "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo=" ];
  };

  outputs = { nixpkgs, nixpkgs-unstable, nixos-hardware, ... }@inputs: let
    _args = import ./args.nix;

    # Configure package repos
    # ----------------------------------------------------------------------------------------------
    system = _args.arch;
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfreePredicate = _: true;
    };
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfreePredicate = _: true;
      config.android_sdk.accept_license = true;
      config.permittedInsecurePackages = [
        #"freeimage-unstable-2021-11-01"     # Allowing this for wii tools
      ];

      # Modify package defaults with overlays
      # --------------------------------------------------------------------------------------------
      overlays = [
        (before: after: {

          # Pinned kernel for T2 linux compatibility
          # - this didn't work and caused glibc and the whole world to be rebuilt
          # linuxKernel = pkgs-kernel.linuxKernel;
          # linuxHeaders = pkgs-kernel.linuxHeaders;
          # linuxPackages = pkgs-kernel.linuxPackages;
          # linuxPackagesFor = pkgs-kernel.linuxPackagesFor;

          # Include custom packages in global pkgs variable
          clu = pkgs.callPackage options/apps/system/clu {};
          arcologout = pkgs.callPackage packages/arcologout {};
          desktop-assets = pkgs.callPackage packages/desktop-assets {};
          rdutil = pkgs.callPackage packages/rdutil {};
          tinymediamanager = pkgs.callPackage packages/tinymediamanager{};
          wmctl = pkgs.callPackage packages/wmctl {};

          # Upgrade select packages to the latest unstable bits
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
  };
}
