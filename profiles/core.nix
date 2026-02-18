# core.nix provides a minimal shell environment on which to build
#
# ### Features
# - Bash shell environment only, no GUI
# - Basic locale, timezone configuration
# - Bash custom configuration
# - Nix flake and commands configuration
# --------------------------------------------------------------------------------------------------
{ config, pkgs, ... }:
{
  imports = [
    ../modules/users.nix
  ];

  # Set the original Nix base version we installed with to ignore the warnings
  system.stateVersion = config.machine.nix.minVer;

  apps.system.neovim.enable = true;     # Essential terminal based text editor
  services.raw.openssh.enable = true;   # SSH tooling

  environment.systemPackages = with pkgs; [
    git                                 # Fast distributed version control system
    jq                                  # Command line JSON processor, depof: kubectl
    logrotate                           # Rotates and compresses system logs
    psmisc                              # Proc filesystem utilities e.g. killall
    sops                                # Industry standard encryption at rest
  ];
}
