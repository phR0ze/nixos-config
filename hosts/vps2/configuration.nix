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
    layers.console.server = {
      enable = true;
      harden = true;
      lowMemory = true;
    };

    # Both the harden layer and sshd's harden flag turn CrowdSec on, so force it back off
    services.native.crowdsec.enable = lib.mkForce false;
  };
}
