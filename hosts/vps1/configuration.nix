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

    # Admin bypass CIDRs now come from args.enc.yaml's host.network.harden.geoblockWhitelist
    # (staged into `machine.network.harden.geoblockWhitelist`, see modules/default.nix) so they
    # stay sops-encrypted rather than living in plaintext here.
  };
}
