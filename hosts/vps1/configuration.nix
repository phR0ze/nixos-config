# vps configuration
#
# ### Features
# - Minimal headless command line system
# - Isolated from shared fleet config/secrets
# - Hardened for public internet consuption
# --------------------------------------------------------------------------------------------------
{

  imports = [
    ./hardware-configuration.nix
  ];

  config = {
    layers.console.core = {
      enable = true;
      lowMemory = true;
      harden = true;
    };

    # RackNerd's KVM guest kernel (confirmed via strace: nix's own sandbox probe does
    # clone(CLONE_NEWNS|CLONE_NEWUSER|CLONE_NEWPID) then mount("none","/proc","proc",...), and that
    # specific mount fails EPERM here - even though each namespace type works fine individually via a
    # plain `unshare`. Only the combined clone()+immediate-procfs-mount path nix's sandbox setup uses
    # is affected, so this is host-specific, not a fleet-wide nixpkgs/module issue. Disabling the
    # build sandbox only affects build-time hermeticity checks for locally-compiled derivations - it
    # has no bearing on this host's runtime hardening (nftables/CrowdSec/sshd/kernel sysctls all still
    # apply) - and this host pulls nearly everything from cache.nixos.org anyway.
    nix.settings.sandbox = false;
  };
}
