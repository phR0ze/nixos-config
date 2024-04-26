# Rust options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.development.rust;
  
in
{
  options = {
    development.rust = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Install and configure rust tooling";
      };
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [
      clang                               # A C language family frontend for LLVM
      lldb                                # Next gen high-performance debugger for Rust
      llvm                                # Compiler infrastructure
      rustup                              # Rust installer
      cargo                               # Rust project dependency management tooling
      rustfmt                             # Rust tool for formatting rust code
    ];
  };
}
