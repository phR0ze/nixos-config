# core.nix provides the foundation for layers
#
# ### Features
# - Basic Nix flake configuration
# - Optional low memory optimizations
# 
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.layers.console.core;
in
{
  options = {
    layers.console.core = {
      enable = lib.mkEnableOption "Enable the core layer";
      lowMemory = lib.mkEnableOption "Enable the low memory configuration";
    };
  };

  config = lib.mkMerge [

    # Standard core
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.enable) {
      system.users.admin.enable = true;             # Create the default admin user

      system.env.clu.enable = true;                 # NixOS orchestration tool
      system.env.nix.enable = true;                 # Enable default nix environment settings
      system.env.bash.enable = true;                # Enable custom bash configuration
      system.env.vars.enable = true;                # Enable standard env variables
      system.env.dircolors.enable = true;           # Enable custom dircolors
      system.env.starship.enable = true;            # Enable the starship shell prompt

      apps.system.git.enable = true;                # Git version control for flake management
      apps.system.neovim.enable = true;             # Best terminal text editor
      apps.system.zellij.enable = true;             # Terminal multiplexing

      services.native.sshd.enable = true;           # Enable SSH configuration
      services.native.systemd.enable = true;        # Enable standard systemd configuration

      environment.systemPackages = with pkgs; [
        # already pulled in by clu:
        # - coreutils gawk gnused jq psmisc sops sudo yq 

        # already pulled in by corePackages:
        # - acl attr bashInteractive bzip2 coreutils-full cpio curl
        # - diffutils findutils gawk getent getconf gnugrep gnupatch gnused gnutar gzip less
        # - libcap ncurses netcat mkpasswd procps su time util-linux which xz zstd

        just                                # A handy way to save and run project-specific commands
        tree                                 # Simple dir listing app in tree form
      ];
    })

    # Low memory
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.enable && cfg.lowMemory) {
      devices.boot.lowMemory = true;                # zram swap to cheaply extend effective memory
      devices.kernel.lowMemory = true;              # aggressive reclaim as swap is in memory
      services.native.systemd.lowMemory  = true;    # cap journld and ensure its persisted
    })
  ];
}
