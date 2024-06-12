# XFCE development configuration
#
# ### Features
# - Directly installable: desktop with additional development tools and configuration
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./desktop.nix
    ../../modules/development/vscode
  ];

  deployment.type.develop = true;

  development.rust.enable = true;
  development.android.enable = true;

  environment.systemPackages = with pkgs; [
    chromium                            # An open source web browser from Google
    google-cloud-sdk                    # Tools for the google cloud platform

    # Standard development
    gnumake                             # A tool to control the generation of non-source files from sources
    pkg-config                          # At tool that allows packages to find out information about other packages

    # Golang development
    go                                  # The Go programming language
    go-bindata                          # Golang code generation utility for embedding binary data in Go programs
    golangci-lint                       # Golang CI linting tool

    # Python
    python3                             # Python 3 runtime
  ];

}
