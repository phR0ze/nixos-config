# XFCE development configuration
#
# ### Features
# - Directly installable: desktop with additional development tools/configs
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./desktop.nix
    ../../modules/development/vscode
  ];

  machine.type.develop = true;

  apps.dev.gh.enable = true;
  apps.dev.rust.enable = true;
  apps.dev.flutter.enable = true;
  apps.dev.claude-code.enable = true;

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

}
