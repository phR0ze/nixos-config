# vm-vps1 configuration
#
# ### Features
# - Minimal headless command line system
# - Isolated from shared fleet config/secrets
# - Hardened, local-VM staging twin of hosts/vps1 - test changes here before they reach production
# --------------------------------------------------------------------------------------------------
{ ... }:

{

  imports = [
    ./hardware-configuration.nix
  ];

  config = {
    layers.console = {
      core = {
        enable = true;
        harden = true;
        lowMemory = true;
      };
      server.enable = true;
    };

    nix.settings.sandbox = false;
  };
}
