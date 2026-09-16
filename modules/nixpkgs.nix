# Shared `nixpkgs.config`/`nixpkgs.overlays` for every host, plus `install` and `iso`. Expressed as
# an ordinary NixOS module (rather than pre-building `pkgs` externally in flake.nix) so that a
# host's own configuration.nix can add to `nixpkgs.config`/`nixpkgs.overlays` itself - the module
# system merges nixpkgs.config key-wise and nixpkgs.overlays as a list, so per-host additions
# (e.g. an extra permittedInsecurePackages entry) compose for free without flake.nix needing to
# know about them.
{ inputs, ... }:
{
  nixpkgs.config = {
    allowUnfreePredicate = pkg: true;
    android_sdk.accept_license = true;
    nvidia.acceptLicense = true;
  };

  nixpkgs.overlays = [
    (final: prev: {
      # Include custom packages in the global pkgs variable to make them available throughout the
      # codebase rather than having to call them with a full path. Note package.nix is used rather
      # than default.nix, as default.nix is reserved for option definitions.
      clu = final.callPackage ./system/env/clu/package.nix { src = inputs.self; };
      arcologout = final.callPackage ../packages/arcologout {};
      desktop-assets = final.callPackage ../packages/desktop-assets {};
      rdutil = final.callPackage ../packages/rdutil {};
      tinymediamanager = final.callPackage ../packages/tinymediamanager {};
      wmctl = final.callPackage ../packages/wmctl {};
    } // (let
      pkgsUnstable = import inputs.nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
        config.allowUnfreePredicate = pkg: true;
        config.android_sdk.accept_license = true;
        config.nvidia.acceptLicense = true;
      };
      in {
        # Override packages with other versions:
        immich = pkgsUnstable.immich;
        vscode = pkgsUnstable.vscode;
        zed-editor = pkgsUnstable.zed-editor;
        zoom-us = pkgsUnstable.zoom-us;
        rust-analyzer = pkgsUnstable.rust-analyzer;
        rust-lang.rust-analyzer = pkgsUnstable.vscode-extensions.rust-lang.rust-analyzer;
        synology-drive-client = pkgsUnstable.synology-drive-client;
        tailscale = pkgsUnstable.tailscale;
        vadimcn.vscode-lldb = pkgsUnstable.vscode-extensions.vadimcn.vscode-lldb;
        vaultwarden = pkgsUnstable.vaultwarden;
        yt-dlp = pkgsUnstable.yt-dlp;
      })
    )
  ];
}
