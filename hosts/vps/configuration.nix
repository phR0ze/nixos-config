# vps configuration
#
# ### Features
# - Minimal headless command line system
# - Isolated from shared fleet config/secrets
# - Hardened for public internet consuption
# --------------------------------------------------------------------------------------------------
{ lib, ... }:
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

    devices.network.harden.bypassGeoBlockCidrs = [
      # "203.0.113.1"
      # "203.0.113.7/32"
    ];
  };
}
