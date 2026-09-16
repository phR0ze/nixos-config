# Kernel/sysctl tuning
#
# --------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  cfg = config.devices.kernel;
in
{
  options = {
    devices.kernel = {
      desktop = lib.mkEnableOption "Enable desktop configuration";
      harden = lib.mkEnableOption "Enable hardening for the kernel";
      lowMemory = lib.mkEnableOption "Enable low memory configuration";
      highMemory = lib.mkEnableOption "Enable high memory configuration";
    };
  };

  config = lib.mkMerge [

    # Harden the kernel security
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.harden) {
      security.lockKernelModules = true;            # block loading new kernel modules once boot is complete
      security.protectKernelImage = true;           # block reading /boot and loading unsigned kernel images at runtime
    })

    # Reduce swapping as we have plenty of memory
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.desktop || cfg.highMemory) {
      boot.kernel.sysctl."vm.swappiness" = 1;       # Minimal amount of swapping without disabling entirely
    })

    # Aggressive reclaim tuning for hosts with limited RAM (e.g. small VMs, VPSs)
    (lib.mkIf (cfg.lowMemory) {
      boot.kernel.sysctl = {
        "vm.swappiness" = 100;                      # high because zram makes swap cheap
        "vm.vfs_cache_pressure" = 50;
        "vm.min_free_kbytes" = 16384;
        "vm.watermark_boost_factor" = 0;            # avoid excessive reclaim boosting on tiny systems
        "vm.watermark_scale_factor" = 125;          # slightly more aggressive kswapd wakeup, helps low-mem
      };
    })

    # Desktop: everything non memory-related
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.desktop) {
      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;                  # Enable ipv4 forwarding for running containers
        "net.ipv6.conf.all.forwarding" = 0;         # Disable ipv6 forwarding

        # These are set by default for x11 but resetting incase I switch to Wayland in the future
        # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/x11/xserver.nix#L749-L750
        "fs.inotify.max_user_watches" = 524288;     # Increase the number of user file watches to max
        "fs.inotify.max_user_instances" = 524288;   # Increase the number of user instances to max

        # Support for bridge virtual switches
        # [netfilter is currently enabled on bridges by default](https://bugzilla.redhat.com/show_bug.cgi?id=512206#c0).
        # This is unneeded additional overhead that can be confusing when trouble shooting. The libvirt team
        # recommends disabling it for all bridge devices.
        "net.bridge.bridge-nf-call-arptables" = 0;
        "net.bridge.bridge-nf-call-ip6tables" = 0;
        "net.bridge.bridge-nf-call-iptables" = 0;
      };

      # Blacklisted modules
      boot.blacklistedKernelModules = [
        "pcspkr"
      ];

#      # Add additional kernel modules
#      boot.extraModprobeConfig = lib.mkIf (qemuHost.enable || obs.enable) (lib.concatStringsSep " " (
#        [ "options" ]
#
#        # Allow nested virtualisation part of virtualisation.qemu.host
#        ++ lib.optionals (qemuHost.enable) [ "kvm_intel nested=1" ]
#
#        # Enable support for OBS virtual camera
#        ++ lib.optionals (obs.enable) [ ''v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1'' ]
#      ));
    })
  ];
}
