# core.nix provides a minimal container environment
#
# ### Features
# - Bash custom shell configuration
# - Basic Nix flake and commands configuration
# --------------------------------------------------------------------------------------------------
{ config, pkgs, ... }:
let
  host = config.host;
in
{
  # Original Nix base version we installed with
  system.stateVersion = host.nix.minVer;

  environment.systemPackages = with pkgs; [
    git                                 # Fast distributed version control system
    jq                                  # Command line JSON processor, depof: kubectl
    logrotate                           # Rotates and compresses system logs
    psmisc                              # Proc filesystem utilities e.g. killall
    sops                                # Industry standard encryption at rest
  ];
}
