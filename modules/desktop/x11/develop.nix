# Development tooling
#
# ### Details
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  imports = [
    ../../development/vscode
    ../../virtualization/virtualbox.nix
  ];

  environment.systemPackages = with pkgs; [
    chromium                            # An open source web browser from Google
    clang                               # A C language family frontend for LLVM
    lldb                                # Next gen high-performance debugger for Rust
    llvm                                # Compiler infrastructure
    rustup                              # Rust installer
  ];
}
