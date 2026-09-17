# Systemd configuration
#
# ### Details
# - Shutdown your system with: poweroff
# - Reboot your system with: reboot
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  cfg = config.services.native.systemd;
in
{
  options = {
    services.native.systemd = {
      enable = lib.mkEnableOption "Enable standard systemd configuration";

      harden = lib.mkEnableOption ''
        additional lockdown not appropriate for a desktop: drops debug-level journal entries.
        Suited to a headless VPS/server, not a desktop
      '';

      lowMemory = lib.mkEnableOption ''
        trims memory usage not appropriate for a desktop: disables VT allocation so no
        getty@ttyN services are spawned (breaks Ctrl+Alt+F2 switching), and disables coredumps
        so a crashing process doesn't spike memory capturing one. Suited to a low-memory/
        underpowered VPS, not a desktop
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {

      # Logind configuration
      # - Defaults were changed here https://github.com/NixOS/nixpkgs/pull/16021
      # - Want shutdown to kill all users process immediately for fast shutdown - undesirable on a
      #   desktop where users expect processes (tmux, background apps) to survive logout
      # ------------------------------------------------------------------------------------------------
      services.logind.settings.Login = {
        KillUserProcesses = true;
        UserStopDelaySec = 0;
      };

      # Journald configuration
      # - Storage=persistent forces logs to disk (/var/log/journal) rather than the volatile tmpfs
      #   fallback (/run/log/journal), so SystemMaxUse bounds real disk usage instead of eating RAM
      # - RuntimeMaxUse bounds the volatile fallback too, in case /var is ever unavailable at boot
      # - Seal=yes: tamper-evident logs (Forward Secure Sealing) - small ongoing CPU cost
      # ------------------------------------------------------------------------------------------------
      services.journald.storage = "persistent";
      services.journald.extraConfig = ''
        SystemMaxUse=256M
        RuntimeMaxUse=64M
        Seal=yes
      '';

      # Timesyncd configuration
      # Defaults are fine
      # ------------------------------------------------------------------------------------------------
      services.timesyncd.enable = lib.mkForce true;
    })

    (lib.mkIf (cfg.enable && cfg.harden) {

      # Journald configuration
      # - MaxLevelStore=info: drop debug-level noise, saving disk and reducing what's exposed to a
      #   reader of the logs - undesirable on a desktop where debug logs help troubleshoot drivers
      #   and apps
      # ------------------------------------------------------------------------------------------------
      services.journald.extraConfig = ''
        MaxLevelStore=info
      '';
    })

    (lib.mkIf (cfg.enable && cfg.lowMemory) {

      # systemd-oomd to kill runaway processes before the kernel OOM killer stalls the system
      systemd.oomd = {
        enable = true;
        enableRootSlice = true;             # activate for root processes
        enableUserSlices = true;            # activate for user processes
      };

      # Logind configuration
      # - NAutoVTs/ReserveVT=0: a headless VPS never uses a virtual terminal, so don't waste memory
      #   spawning getty@ttyN services for one - undesirable on a desktop that relies on VT
      #   switching (e.g. Ctrl+Alt+F2)
      # ------------------------------------------------------------------------------------------------
      services.logind.settings.Login = {
        NAutoVTs = 0;
        ReserveVT = 0;
      };

      # Coredump configuration
      # - Disabled: a large crashing process can spike memory just to capture a dump nobody reviews
      #   on an underpowered VPS - undesirable on a desktop where coredumps are used to debug/report
      #   crashing apps
      # ------------------------------------------------------------------------------------------------
      systemd.coredump.enable = false;
      systemd.settings.Manager.DefaultLimitCORE = 0;
    })
  ];
}
