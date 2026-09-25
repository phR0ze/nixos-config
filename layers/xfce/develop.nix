# develop.nix provides a full XFCE desktop with development tooling
#
# ### Dependencies
# - `xfce.desktop` gets enabled for the full desktop environment
#
# ### Features
# - Desktop with additional development tools/configs
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.layers.xfce.develop;
in
{
  options = {
    layers.xfce.develop = {
      enable = lib.mkEnableOption "Enable the xfce develop layer";
      lowMemory = lib.mkEnableOption "Enable the low memory configuration";
    };
  };

  config = lib.mkMerge [

    (lib.mkIf (cfg.enable) {

      # Desktop dependency with passed along configuration
      layers.xfce.desktop = {
        enable = true;
        lowMemory = lib.mkIf cfg.lowMemory true;
      };

      host.type.develop = true;

      apps.dev.gh.enable = true;
      apps.dev.rust.enable = true;
      apps.dev.flutter.enable = true;
      apps.dev.vscode.enable = true;

      environment.systemPackages = with pkgs; [
        chromium                            # An open source web browser from Google
        google-cloud-sdk                    # Tools for the google cloud platform
        sqlitebrowser                       # Simple tool for browsing a sqlite DB

        # Golang development
        go                                  # The Go programming language
        go-bindata                          # Golang code generation utility for embedding binary data in Go programs
        golangci-lint                       # Golang CI linting tool

        # Python
        python3                             # Python 3 runtime
      ];
    })
  ];
}
