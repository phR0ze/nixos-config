# Development tooling
#
# ### Details
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  imports = [
    ../../development/vscode
  ];

  # Add cargo's bin to the environment 
  environment.extraInit = ''
    export PATH="$HOME/.cargo/bin"
  '';

  environment.systemPackages = with pkgs; [
    chromium                            # An open source web browser from Google
    clang                               # A C language family frontend for LLVM
    lldb                                # Next gen high-performance debugger for Rust
    llvm                                # Compiler infrastructure
    rustup                              # Rust installer
    cargo                               # Rust project dependency management tooling
    rustfmt                             # Rust tool for formatting rust code
  ];
}
