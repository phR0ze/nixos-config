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
    layers.console.core = {
      enable = true;
      lowMemory = true;
      harden = true;
    };

    devices.network.geoblock = {
      enable = true;
      allowExtraCidrs = [
        # Add your own known-static management/VPN egress CIDR(s) here as a lockout safety net
        # before relying on this in production, e.g. "203.0.113.7/32" - see the option's doc.
      ];
    };
  };
}
