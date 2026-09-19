# server.nix provides the container runtime foundation for headless server-class hosts
#
# ### Features
# - Podman (rootless-capable OCI container runtime, docker-compatible CLI/socket)
# --------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  cfg = config.layers.console.server;
in
{
  options = {
    layers.console.server = {
      enable = lib.mkEnableOption "Enable the server layer";
    };
  };

  config = lib.mkIf (cfg.enable) {
    devices.kernel.containers = true;      # ip_forward/bridge-nf-call sysctls podman needs
    virtualisation.podman.enable = true;   # OCI container runtime for services.oci.* modules
  };
}
