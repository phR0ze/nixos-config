# core.nix provides the foundation for layers
#
# ### Features
# - Basic Nix flake configuration
# - Optional low memory optimizations
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.layers.console.core;
in
{
  options = {
    layers.console.core = {
      enable = lib.mkEnableOption "Enable the core layer";
      harden = lib.mkEnableOption "Enable security hardening configuration";
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
      system.env.git.enable = true;                 # Git version control for flake management
      system.env.bash.enable = true;                # Enable custom bash configuration
      system.env.vars.enable = true;                # Enable standard env variables
      system.env.dircolors.enable = true;           # Enable custom dircolors
      system.env.systemd.enable = true;             # Enable standard systemd configuration
      system.env.neovim.enable = true;              # Best terminal text editor
      system.env.starship.enable = true;            # Enable the starship shell prompt
      system.env.zellij.enable = true;              # Terminal multiplexing

    })

    # Low memory
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.enable && cfg.lowMemory) {
      devices.boot.lowMemory = true;                # zram swap to cheaply extend effective memory
      devices.kernel.lowMemory = true;              # aggressive reclaim as swap is in memory
      system.env.systemd.lowMemory  = true;         # cap journld and ensure its persisted
    })

    # Harden
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.enable && cfg.harden) {
      networking.domain = "";                       # always required fuly-qualified names
      networking.firewall.allowPing = lib.mkForce false;

      devices.boot.harden = true;                   # clean /tmp on every boot
      devices.kernel.harden = true;                 # include kernel hardening configuration
      system.env.systemd.harden = true;             # additional security and low memory options
    })
  ];
}
