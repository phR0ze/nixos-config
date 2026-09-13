# low-mem.nix provides tuning for hosts with limited RAM (e.g. small VMs, SBCs)
#
# ### Features
# - zram swap to cheaply extend effective memory
# - Sysctl tuning favoring aggressive reclaim over disk swap thrash
# - systemd-oomd to kill runaway processes before the kernel OOM killer stalls the system
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;                 # zram size relative to RAM; try 75-100 on a 2GB box
    priority = 100;
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 100;              # high because zram makes swap cheap
    "vm.vfs_cache_pressure" = 50;
    "vm.min_free_kbytes" = 16384;
    "vm.watermark_boost_factor" = 0;    # avoid excessive reclaim boosting on tiny systems
    "vm.watermark_scale_factor" = 125;  # slightly more aggressive kswapd wakeup, helps low-mem
  };

  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableUserSlices = true;
  };
}
