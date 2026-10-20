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
      pangolinTag = "ee-1.24.0";
      gerbilTag = "1.5.2";
      traefikTag = "v3.7";
      crowdsecTag = "v1.7.8";  # agent only, must not be newer than the host LAPI
      badgerPluginVersion = "v1.7.0";
      crowdsecPluginVersion = "v1.7.1";
    };
  };
}
