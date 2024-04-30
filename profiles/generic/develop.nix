# XFCE development configuration
#
# ### Features
# - Directly installable: generic/desktop with additional development tools and configuration
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./desktop.nix
    ../../modules/development/vscode
  ];

  development.rust.enable = true;

  services.xserver.desktopManager.xfce.menu.overrides = [
    { source = "${pkgs.vscode}/share/applications/code.desktop"; categories = "Development"; }
  ];

  environment.systemPackages = with pkgs; [
    chromium                            # An open source web browser from Google
    gnumake                             # A tool to control the generation of non-source files from sources
    google-cloud-sdk                    # Tools for the google cloud platform
    go                                  # The Go programming language
    go-bindata                          # Golang code generation utility for embedding binary data in Go programs
    golangci-lint                       # Golang CI linting tool
  ];
}
