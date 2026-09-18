# vps configuration
#
# ### Features
# - Minimal headless command line system
# - Isolated from shared fleet config/secrets
# - Hardened for public internet consuption
# --------------------------------------------------------------------------------------------------
{ config, ... }:

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

    # CrowdSec Central API (CAPI) enrollment: lets this host's bouncer drop IPs already flagged by
    # the wider CrowdSec community, not just ones this box has personally caught attacking it. The
    # credentials file itself is produced by `cscli capi register` run once on the VPS (see the
    # runbook) and stored as a single sops key in this host's own secrets.enc.yaml (isolated host,
    # so this never touches the fleet's shared secrets) - decrypted at activation to
    # /run/secrets/crowdsec/capiCredentials, never the Nix store.
    #secret.files."crowdsec/capiCredentials".sopsFile = config.host.secrets;
    #services.native.crowdsec.capiCredentialsFile = config.secret.files."crowdsec/capiCredentials".path;

    # RackNerd's KVM guest kernel (confirmed via strace: nix's own sandbox probe does
    # clone(CLONE_NEWNS|CLONE_NEWUSER|CLONE_NEWPID) then mount("none","/proc","proc",...), and that
    # specific mount fails EPERM here - even though each namespace type works fine individually via a
    # plain `unshare`. Only the combined clone()+immediate-procfs-mount path nix's sandbox setup uses
    # is affected, so this is host-specific, not a fleet-wide nixpkgs/module issue. Disabling the
    # build sandbox only affects build-time hermeticity checks for locally-compiled derivations - it
    # has no bearing on this host's runtime hardening (nftables/CrowdSec/sshd/kernel sysctls all still
    # apply) - and this host pulls nearly everything from cache.nixos.org anyway.
    #nix.settings.sandbox = false;
  };
}
