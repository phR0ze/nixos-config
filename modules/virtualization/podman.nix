# Podman configuration
#
# ### Prerequisites
# `devices.kernel.containers = true` (modules/devices/kernel.nix) sets the required
# net.ipv4.ip_forward/net.bridge.bridge-nf-call-* sysctls - already implied for desktop hosts via
# devices.kernel.desktop, and turned on for headless hosts by layers/console/server.nix.
#
# ### Notes
# - See README.md for usage details
# - `virtualization.podman.enable` wraps NixOS's own `virtualisation.podman.enable` — setting it
#   also pulls in this module's extra opinionated config: the primary user's `podman` group
#   membership, podman-compose, container-name DNS on custom networks, and weekly autoPrune.
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.virtualization.podman;
in
{
  options.virtualization.podman = {
    enable = lib.mkEnableOption "Podman with this repo's opinionated defaults (see modules/virtualization/podman.nix)";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.podman.enable = true;

    # ip_forward/bridge-nf-call sysctls podman needs
    devices.kernel.containers = true;

    # Configure primary user permissions - merges onto the same secret.users."admin" entry
    # modules/system/users.nix declares (real username only known post-decrypt, see
    # modules/devices/network.nix's networkmanager grant for the same pattern)
    secret.users."admin".extraGroups = [ "podman" ];

    # Install dependencies
    environment.systemPackages = [
      pkgs.podman-compose
    ];

    # Enable container name DNS for non-default Podman networks.
    # https://github.com/NixOS/nixpkgs/issues/226365
    #
    # `networking.firewall.interfaces."podman+"` (the iptables-era wildcard-suffix idiom from that
    # issue) doesn't translate under the nftables backend (devices.network.harden.enable turns on
    # networking.nftables.enable) - the generated ruleset interpolates the interface name
    # unquoted, and a bare trailing "+" is a syntax error to nft, not a wildcard. nftables' own
    # glob operator is "*", written here directly via extraInputRules instead.
    networking.firewall.extraInputRules = ''
      iifname "podman*" udp dport 53 accept
    '';

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
