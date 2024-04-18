# Development tooling
#
# ### Details
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  imports = [
    ../../services/barrier.nix
  ];

  # Additional programs and services
  services.barriers.enable = true;      # Enable the barrier server and client

  environment.systemPackages = with pkgs; [
    rustup                              # Rust installer
  ];
}
