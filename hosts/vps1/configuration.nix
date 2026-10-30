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
    layers.console.server = {
      enable = true;
      harden = true;
      lowMemory = true;
    };
    services.oci.pangolin = {
      enable = true;
      pangolinTag = "ee-1.25.3";
      gerbilTag = "1.5.2";
      traefikTag = "v3.7.16";
      crowdsecTag = "v1.7.8";  # agent only, must not be newer than the host LAPI
      badgerPluginVersion = "v1.7.0";
      crowdsecPluginVersion = "v1.7.1";
      webdavSubdomains = [ "nextcloud" ];   # homelab's Nextcloud, see crowdsecAppsecExclusionsText
    };

    # TEMPORARY: CVE-2026-98432 (remote TCP use-after-free, fixed in 6.18.56) is reachable via the
    # MPTCP listeners Go >= 1.24 opens by default (traefik, gerbil, crowdsec). Disabling MPTCP makes
    # them fall back to plain TCP. Remove once the nixpkgs pin bump puts this host on >= 6.18.56.
    boot.kernel.sysctl."net.mptcp.enabled" = 0;
  };
}
