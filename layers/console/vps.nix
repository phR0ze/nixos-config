# vps.nix provides a hardenend minimal server environment
#
# ### Background
# The target system for this configuration is a public virtual private server. These types of systems
# typically don't provide an option for installing directly from a NixOS iso and require using
# nixos-infect to get started.
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
  system.stateVersion = config.host.nix.minVer;

  apps.dev.git.enable = true;                     # Git version control for flake management
  apps.system.neovim.enable = true;               # Terminal text editor
  apps.system.zellij.enable = true;               # Terminal multiplexing

  environment.systemPackages = with pkgs; [
    git                                 # Fast distributed version control system
    jq                                  # Command line JSON processor, depof: kubectl
    logrotate                           # Rotates and compresses system logs
    psmisc                              # Proc filesystem utilities e.g. killall
    sops                                # Industry standard encryption at rest
  ];

  # Admin account with secret username and password
  secret.users."admin" = {
    sopsFile = host.secrets;
    userSecretRef = "user/name";
    groupSecretRef = "user/group";
    passwordHashSecretRef = "user/passwordHash";
    isNormalUser = true;
    uid = 1000;
    extraGroups = [
      "wheel"                                     # enables sudo access for this user
    ];
  };
}
