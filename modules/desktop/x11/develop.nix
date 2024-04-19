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
    lldb                                # Next gen high-performance debugger for Rust
    rustup                              # Rust installer
  ];
}
