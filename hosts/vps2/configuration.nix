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
  };
}
