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

      system.env.nix.enable = true;                 # Enable default nix environment settings
      system.env.bash.enable = true;                # Enable custom bash configuration
      system.env.vars.enable = true;                # Enable standard env variables
      system.env.dircolors.enable = true;           # Enable custom dircolors

      apps.dev.git.enable = true;                   # Git version control for flake management
      apps.system.neovim.enable = true;             # Terminal text editor
      apps.system.zellij.enable = true;             # Terminal multiplexing

      # Fundamental packages all systems share
      environment.systemPackages = with pkgs; [

        # clu support
        git                                 # Fast distributed version control system
        jq                                   # Command line JSON processor, depof: kubectl
        psmisc                                # Proc filesystem utilities e.g. killall
        sops                                # Industry standard encryption at rest

        # essential utilities
        logrotate                           # Rotates and compresses system logs
      ];
    })

    # Low memory
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.enable && cfg.lowMemory) {

      # Sysctl tuning favoring aggressive reclaim over disk swap thrash 
      devices.kernel.lowMemory = true;

      # zram swap cheaply extends effective memory by taking a portion of the physical memory and
      # turning it into a compressed swap. this will allow for over doubling the available size
      zramSwap = {
        enable = true;
        algorithm = "zstd";                         # default compression algorithm
        memoryPercent = 50;                         # zram size relative to RAM
        priority = 100;                             # use this before disk swap
      };

      # systemd-oomd to kill runaway processes before the kernel OOM killer stalls the system
      systemd.oomd = {
        enable = true;
        enableRootSlice = true;
        enableUserSlices = true;
      };
    })

    # Harden the core
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.enable && cfg.harden) {

      # Network hardening
      networking.domain = "";                       # always required fuly-qualified names
      networking.firewall.allowPing = lib.mkForce false;

      boot.tmp.cleanOnBoot = true;                  # clean /tmp on every boot
      security.lockKernelModules = true;            # block loading new kernel modules once boot is complete
      security.protectKernelImage = true;           # block reading /boot and loading unsigned kernel images at runtime
    })
  ];
}
