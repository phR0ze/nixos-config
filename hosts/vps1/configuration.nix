# vps configuration
#
# ### Features
# - Minimal headless command line system
# - Isolated from shared fleet config/secrets
# - Hardened for public internet consuption
# --------------------------------------------------------------------------------------------------
{ ... }:

{

  imports = [
    ./hardware-configuration.nix
  ];

  config = {
    layers.console = {
      core = {
        enable = true;
        lowMemory = true;
      };
      server = {
        enable = true;
        harden = true;
      };
    };

    # sshd.service's own systemd sandboxing (services.native.sshd's harden block) cascades to every
    # login shell forked from it - same mechanism as the RestrictNamespaces exclusion documented
    # there, just a wider blast radius than that one flag alone. Confirmed via bisection with
    # `systemd-run` (isolated transient units carrying sshd's exact serviceConfig, zero sshd
    # ancestry): `ProtectKernelTunables=true` alone breaks a nested user+pid+mount namespace's
    # `mount("none","/proc","proc",...)` with EPERM, and separately `ProtectControlGroups=true` +
    # `ProtectHostname=true` together do too (neither alone does) - exactly what nix's own sandbox
    # setup does for every locally-built derivation, so `nix build` over any SSH session forked after
    # that hardening lands fails with "this system does not support the kernel namespaces...". Not a
    # RackNerd/kernel issue - reproduces identically via plain `unshare` outside of Nix entirely.
    #
    # Stripping those directives off sshd.service to preserve the build sandbox would trade away real
    # hardening (and there may be other untested combinations with the same effect) for a build-time
    # only concern, so the tradeoff is taken here instead: disabling the sandbox only affects
    # hermeticity checks for locally-compiled derivations, not this host's runtime hardening
    # (nftables/CrowdSec/sshd/kernel sysctls all still apply) - and this host pulls nearly everything
    # from cache.nixos.org anyway.
    nix.settings.sandbox = false;
  };
}
