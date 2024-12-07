# Podman configuration
#
# ### Prerequisites
# The following kernel params already setup in nixos-config/modules/boot/kerel.nix are required
# ```nix
# boot.kernel.sysctl = {
#   "net.ipv4.ip_forward" = 1;
#   "net.bridge.bridge-nf-call-arptables" = 0;
#   "net.bridge.bridge-nf-call-ip6tables" = 0;
#   "net.bridge.bridge-nf-call-iptables" = 0;
# };
# ```
#
# ### Features
# - purposefully renaming `virtualization` to give me a new namespace to work in
#
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.virtualization.podman;

in
{
  options = {
    virtualization.podman = {
      enable = lib.mkEnableOption "Install and configure Podman";
    };
  };

  config = lib.mkIf (cfg.enable) {

    # Configure primary user permissions
    users.users.${args.username}.extraGroups = [ "podman" ];

    # Install dependencies
    environment.systemPackages = [
      pkgs.podman-compose
    ];

    # Set the default backend container technology to podman
    virtualisation.oci-containers.backend = "podman";

    # Enable container name DNS for non-default Podman networks.
    # https://github.com/NixOS/nixpkgs/issues/226365
    networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

    # Enable and configure podman
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;            # provide docker alias
      dockerSocket.enable = true;     # link podman socket as /var/run/docker.sock requires restart

      # Allows docker containers to refer to each other by name
      defaultNetwork.settings.dns_enabled = true;

      # Removes dangling containers and images that are not being used. It won't remove any volumes by default
      autoPrune = {
        enable = true;
        dates = "weekly";

        # Removes stuff older than 24h and doesn't have the label important
        flags = [
          "--filter=until=24h"
          "--filter=label!=important"
        ];
      };
    };
  };
}
