# vm-vps1 configuration
#
# ### Features
# - Minimal headless command line system
# - Isolated from shared fleet config/secrets
# - Hardened, local-VM staging twin of hosts/vps1 - test changes here before they reach production
# --------------------------------------------------------------------------------------------------
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
      pangolinTag = "ee-1.21.1";
      gerbilTag = "1.5.1";
      traefikTag = "v3.7";
      crowdsecTag = "v1.7.8";
      badgerPluginVersion = "v1.5.0";
      crowdsecPluginVersion = "v1.4.4";
    };
  };
}
