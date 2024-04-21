# Development tooling
#
# ### Details
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  imports = [
    ../../development/vscode
    ../../services/barrier.nix
  ];

  # Additional programs and services
  services.barriers.enable = true;      # Enable the barrier server and client

  environment.systemPackages = with pkgs; [
    chromium                            # An open source web browser from Google
    clang                               # A C language family frontend for LLVM
    lldb                                # Next gen high-performance debugger for Rust
    llvm                                # Compiler infrastructure
    rustup                              # Rust installer
  ];
}
