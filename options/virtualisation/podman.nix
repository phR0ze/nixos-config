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
#
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.virtualisation.podman;
in
{
  config = lib.mkIf (cfg.enable) {

    # Configure primary user permissions
    users.users.${machine.user.name}.extraGroups = [ "podman" ];

    # Install dependencies
    environment.systemPackages = [
      pkgs.podman-compose
    ];

    # Enable container name DNS for non-default Podman networks.
    # https://github.com/NixOS/nixpkgs/issues/226365
    networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

    # Default backend is already podman and when this is uncommented a recursion bug occurs
    # so I'll just leave this here as a reminder but nothing is needed.
    #virtualisation.oci-containers.backend = "podman";

    # Enable and configure podman
    virtualisation.podman = {
      dockerCompat = true;            # provide docker alias
      dockerSocket.enable = true;     # link podman socket as /var/run/docker.sock requires restart

      # Allows docker containers to refer to each other by name
      defaultNetwork.settings.dns_enabled = true;

      # Removes dangling containers and images that are not being used.
      # Note: It won't remove any volumes by default
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [
          "--filter=until=24h"
          "--filter=label!=important"
        ];
      };
    };
  };
}
