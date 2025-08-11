# core.nix provides a minimal shell environment on which to build
#
# ### Features
# - Bash shell environment only, no GUI
# - Basic locale, timezone configuration
# - Bash custom configuration
# - Nix flake and commands configuration
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, ... }:
let
  machine = config.machine;
in
{
  imports = [
    ../modules/users.nix
  ];

  # Set the original Nix base version we installed with to ignore the warnings
  system.stateVersion = config.machine.nix.minVer;

  programs.neovim.enable = true;
  services.speechd.enable = false;
  services.raw.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    git                           # Fast distributed version control system
    jq                            # Command line JSON processor, depof: kubectl
    logrotate                     # Rotates and compresses system logs
    psmisc                        # Proc filesystem utilities e.g. killall
    sops                          # Industry standard encryption at rest
  ];
}
