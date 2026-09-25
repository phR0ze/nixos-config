# server.nix provides the container runtime foundation for headless server-class hosts
# 
# ### Dependencies
# - `core` gets configured with passed along options
#
# ### Features
# - Podman (rootless-capable OCI container runtime, docker-compatible CLI/socket)
# - Optional security hardening configuration
# --------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  cfg = config.layers.console.server;
in
{
  options = {
    layers.console.server = {
      enable = lib.mkEnableOption "Enable the server layer";
      harden = lib.mkEnableOption "Enable security hardening configuration";
      lowMemory = lib.mkEnableOption "Enable the low memory configuration";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # Core dependencies with passed along configuration
      layers.console.core = {
        enable = true;
        lowMemory = lib.mkIf cfg.lowMemory true;
      };

      # OCI container runtime for services.oci.* modules
      virtualisation.podman.enable = true;
    }

    # Harden
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf cfg.harden {
      devices.boot.harden = true;                   # clean /tmp on every boot
      devices.kernel.harden = true;                 # include kernel hardening configuration
      devices.network.harden.enable = true;         # networking hardening, incl. geo-block

      services.native.sshd.harden = true;           # restrict sshd and enable CrowdSec brute-force protection
      services.native.systemd.harden = true;        # additional security and low memory options
      services.native.crowdsec.enable = true;       # enable broad CrowdSec protection
      services.native.alerts.enable = true;         # push failed-unit alerts + a daily security digest
    })
  ]);
}
