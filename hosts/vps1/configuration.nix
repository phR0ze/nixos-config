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
      pangolinTag = "ee-1.27.1";
      gerbilTag = "1.6.0";
      traefikTag = "v3.8.0";
      crowdsecTag = "v1.8.2";  # agent only, must not be newer than the host LAPI
      badgerPluginVersion = "v1.8.0";
      crowdsecPluginVersion = "v1.8.2";
      webdavSubdomains = [ "nextcloud" "nextcloud-vpn" ]; # homelab's Nextcloud, see crowdsecAppsecExclusionsText
    };
  };
}
