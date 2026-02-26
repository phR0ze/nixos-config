# Rust options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.dev.rust;
in
{
  options = {
    apps.dev.rust = {
      enable = lib.mkEnableOption "Install and configure rust tooling";
    };
  };
 
  config = lib.mkIf (cfg.enable) {

    # Add cargo installed binaries to the path
    environment.extraInit = ''
      export PATH="$HOME/.cargo/bin:$PATH"
    '';

    # Set the rust source path for rust-analyzer to be happy
    environment.sessionVariables.RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

    environment.systemPackages = with pkgs; [
      clang                               # A C language family frontend for LLVM
      lldb                                # Next gen high-performance debugger for Rust
      llvm                                # Compiler infrastructure
      llvmPackages.bintools               # Use lld instead of ld

      # Rust dependencies
      cargo                               # Rust project dependency management tooling
      rustc                               # Ensure we have Rust 1.86 or newer available
      glibc                               # System dependency for SQLx macros
      sqlx-cli                            # SQLx command line tool

      # C++ dependency build requirements
      gnumake                             # A tool to control the generation of non-source files from sources
      pkg-config                          # At tool that allows packages to find out information about other packages
      openssl                             # Cryptocraphic implementation of the SSL and TLS protocols
      openssl.dev                         # Development headers for Open SSL
      gtk4                                # Multi-platform toolkit for creating graphical user interfaces

      # Development tools
      mysql-workbench                     # Useful for designing relational table EER Diagrams
      sqlitebrowser                       # Useful for examining the database
    ];

#    rustToolchain =
#            # This should be kept in sync with the value in bazel/rust/defs.bzl
#            pkgs.rust-bin.nightly."2024-09-05".default.override {
#              extensions = [
#                "clippy"
#                "llvm-tools-preview"
#                "rust-analyzer"
#                "rust-src"
#                "rustfmt"
#              ];
#              targets = [
#                "wasm32-unknown-unknown"
#                "x86_64-unknown-linux-musl"
#                "x86_64-unknown-none"
#              ];
#            };
#          craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;
#          src = ./.;
  };
}
