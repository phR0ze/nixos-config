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
      harden = lib.mkEnableOption "Enable hardening for the kernel";
      lowMemory = lib.mkEnableOption "Enable low memory configuration";
      containers = lib.mkEnableOption "Enable sysctl tuning required for running containers (podman/docker)";
      desktop = lib.mkEnableOption "Enable additional desktop related kernel settings";
    };
  };

  config = lib.mkMerge [

    # Reduce swapping as we have plenty of memory
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (!cfg.lowMemory) {
      boot.kernel.sysctl = {
        "vm.swappiness" = 1;                        # Minimal amount of swapping without disabling entirely

        # These are set by default for x11 but resetting incase I switch to Wayland in the future
        # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/x11/xserver.nix#L749-L750
        "fs.inotify.max_user_watches" = 524288;     # Increase the number of user file watches to max
        "fs.inotify.max_user_instances" = 524288;   # Increase the number of user instances to max
      };
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

    # Container runtime: bridge/forwarding sysctls needed by podman/docker (and libvirt/qemu
    # bridges) - split out from the desktop block below so headless server hosts (e.g. hosts/vps1)
    # can opt in via layers/console/server.nix without pulling in desktop-only tuning.
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.containers) {
      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;                  # Enable ipv4 forwarding for running containers

        # Support for bridge virtual switches
        # [netfilter is currently enabled on bridges by default](https://bugzilla.redhat.com/show_bug.cgi?id=512206#c0).
        # This is unneeded additional overhead that can be confusing when trouble shooting. The libvirt team
        # recommends disabling it for all bridge devices.
        "net.bridge.bridge-nf-call-arptables" = 0;
        "net.bridge.bridge-nf-call-ip6tables" = 0;
        "net.bridge.bridge-nf-call-iptables" = 0;
      };
    })

    # Add additional kernel modules
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.desktop) {
      # boot.extraModprobeConfig = lib.mkIf (qemuHost.enable || obs.enable) (lib.concatStringsSep " " (
      #   [ "options" ]
      #
      #   # Allow nested virtualisation part of virtualization.qemu.host
      #   ++ lib.optionals (qemuHost.enable) [ "kvm_intel nested=1" ]
      #
      #   # Enable support for OBS virtual camera
      #   ++ lib.optionals (obs.enable) [ ''v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1'' ]

      # Blacklisted modules
      boot.blacklistedKernelModules = [
        "pcspkr"
      ];
    })

    # Harden the kernel security
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.harden) {
      security.lockKernelModules = true;            # block loading new kernel modules once boot is complete
      security.protectKernelImage = true;           # block reading /boot and loading unsigned kernel images at runtime

      # Every kernel module any harden-adjacent feature needs, gathered here rather than scattered
      # per-module - centralized because they all share one root cause: security.lockKernelModules
      # below sets kernel.modules_disabled=1 once boot completes (a one-way door, applied by
      # systemd-sysctl.service, which orders after systemd-modules-load.service within
      # sysinit.target - systemd's own default), so anything that would otherwise autoload on first
      # use must already be loaded before that point instead, for as long as this host is hardened.
      # Assumes devices.kernel.harden is always paired with devices.network.harden.enable/
      # services.native.crowdsec.enable, true today only via layers/console/core.nix's harden flag
      # turning all three on together - a host enabling those features standalone without
      # devices.kernel.harden doesn't need any of this, since on-demand autoload still works fine.
      boot.kernelModules = [
        "af_packet"     # AF_PACKET raw sockets (libpcap-based capture: tcpdump, rustnet, etc) -
                        #   without this, any AF_PACKET socket() call fails with EAFNOSUPPORT ("PF_PACKET
                        #   sockets not supported" in libpcap's own wording) even for root (confirmed
                        #   live on hosts/vps1)
        "nf_tables"     # nftables core - services.native.crowdsec, devices.network.harden's geoblock
                        #   and connlimit tables all need this; without it nftables.service fails to
                        #   load ANY table at all on this host
        "nft_limit"     # nftables `limit rate` expression - devices.network.harden's connlimit
                        #   chain; without this, `nft -f` fails with a misleading "Could not process
                        #   rule: No such file or directory" the moment that table is (re)loaded
                        #   (confirmed live on hosts/vps1)
        "br_netfilter"  # bridge netfilter hooks - the net.bridge.bridge-nf-call-* sysctls below
                        #   (devices.kernel.containers) don't exist under /proc/sys until this is
                        #   loaded, and podman's first bridge-network creation needs it too
        "veth"          # virtual ethernet pairs - netavark's per-container network setup needs this
                        #   to create each container's veth pair; without it, container start fails
                        #   with "netavark: create veth pair: Netlink error: Operation not supported"
                        #   (confirmed live on hosts/vm-vps1)
        "nft_nat"       # nftables `type nat` chain expression - the base module every one of
                        #   netavark's PREROUTING/POSTROUTING/OUTPUT nat-hook chains declares
                        #   (hostport DNAT, masquerade); without it those chains fail to load with
                        #   the same misleading "Could not process rule: No such file or directory"
                        #   as nft_limit/nft_masq below (confirmed live on hosts/vm-vps1, found via
                        #   lsmod reconciliation after a clean lockKernelModules=false boot - it was
                        #   loading fine on-demand but had been missed off this explicit list)
        "nft_masq"      # nftables masquerade expression - netavark's per-network NAT ruleset (outbound
                        #   internet access for containers) uses this; without it `nft` fails applying
                        #   netavark's ruleset with a misleading "Could not process rule: No such file
                        #   or directory", same symptom class as nft_limit above (confirmed live on
                        #   hosts/vm-vps1)
        "nft_chain_nat" # nftables NAT chain type - part of the same netavark ruleset as nft_masq above;
                        #   pulls in nf_nat as a dependency
        "nft_ct"        # nftables conntrack match/set expressions - netavark's established/related
                        #   rules in the same ruleset; pulls in nf_conntrack as a dependency
        "nft_fib_inet"  # nftables fib lookup (inet family) - netavark's routing-decision rules in the
                        #   same ruleset; pulls in nft_fib_ipv4/nft_fib_ipv6/nft_fib as dependencies
        "nft_log"       # nftables log expression - netavark's ruleset includes log rules
      ];

      boot.kernel.sysctl = {
        # Network stack: SYN flood / spoofing / redirect hardening
        "net.ipv4.tcp_syncookies" = 1;
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.all.secure_redirects" = 0;
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv4.conf.default.accept_source_route" = 0;
        "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
        "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
        "net.ipv4.conf.all.log_martians" = 1;

        # BPF hardening
        "net.core.bpf_jit_harden" = 2;
        "kernel.unprivileged_bpf_disabled" = 1;

        # Kernel info-leak / ptrace / misc hardening
        "kernel.kptr_restrict" = 2;
        "kernel.dmesg_restrict" = 1;
        "kernel.yama.ptrace_scope" = 1;
        "kernel.sysrq" = 0;
      };
    })
  ];
}
