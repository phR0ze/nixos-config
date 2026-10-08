# vm-vps1 configuration
#
# ### Features
# - Minimal headless command line system
# - Isolated from shared fleet config/secrets
# - Hardened, local-VM staging twin of hosts/vps1 - test changes here before they reach production
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  # imports = [
  #   ./hardware-configuration.nix
  # ];

  config = {

    # VM specification
    host.type.vm = true;
    virtualization.qemu.guest = {
      cores = 2;
      memorySize = 2;
      rootDrive.size = 30;
      network.macvtap = true;
    };

    # Server specification
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

    # Console enrollment for its extra blocklists - needs crowdsec/consoleEnrollKey in secrets
    services.native.crowdsec.console.enroll = true;
  };
}
