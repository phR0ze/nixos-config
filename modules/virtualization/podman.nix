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

  # Every `host_interface_name=` set on an oci-containers network attachment (see `f.contVeth`),
  # whose 15-character truncation could make two containers collide
  hostVeths = lib.concatMap (c: lib.concatMap (n:
      let m = builtins.match ".*host_interface_name=([^,]+).*" n; in lib.optional (m != null) (lib.head m))
    c.networks) (lib.attrValues config.virtualisation.oci-containers.containers);
  duplicateVeths = lib.attrNames (lib.filterAttrs (_: v: lib.length v > 1) (lib.groupBy (x: x) hostVeths));
in
{
  options.virtualization.podman = {
    enable = lib.mkEnableOption "Podman with this repo's opinionated defaults (see modules/virtualization/podman.nix)";
    harden = lib.mkEnableOption ''
      Drop the docker-compatible socket and keep the admin user out of the `podman` group. Either
      one grants root-equivalent access to the rootful podman API without going through sudo
    '';
  };

  config = lib.mkIf cfg.enable {
    virtualisation.podman.enable = true;

    # Two containers with the same veth name would fail at start with an opaque netlink error
    assertions = [
      { assertion = duplicateVeths == [ ];
        message = "podman: containers share a host veth name after f.contVeth's 15-character truncation: ${lib.concatStringsSep ", " duplicateVeths}";
      }
    ];

    # ip_forward/bridge-nf-call sysctls podman needs
    devices.kernel.containers = true;

    # Configure primary user permissions
    system.users.admin.extraGroups = lib.optional (!cfg.harden) "podman";

    # The admin user comes from nix-weave's secret users, whose extraGroups are only ever added
    # (`usermod -aG`), never removed - so a host hardened after the fact kept the admin in `podman`
    # (hosts/vm-vps1, 2026-10-07). Empty the group on every activation instead.
    system.activationScripts.podmanHardenGroup = lib.mkIf cfg.harden (lib.stringAfter [ "users" "groups" ] ''
      for u in $(${pkgs.getent}/bin/getent group podman | ${pkgs.coreutils}/bin/cut -d: -f4 | ${pkgs.coreutils}/bin/tr , ' '); do
        ${pkgs.shadow}/bin/gpasswd -d "$u" podman
      done
    '');

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
    #
    # Fleet convention: every podman bridge matches "podman*" - podman's own auto-named `podmanN`
    # (e.g. podman-compose stacks) and every services.oci.* network via `f.contBridge`
    # ("podman-<name>"). Rules that should cover container bridges match that glob.
    networking.firewall.extraInputRules = ''
      iifname "podman*" udp dport 53 accept
    '';

    # Default backend is already podman and when this is uncommented a recursion bug occurs
    # so I'll just leave this here as a reminder but nothing is needed.
    #virtualisation.oci-containers.backend = "podman";

    # Enable and configure podman
    virtualisation.podman = {
      dockerCompat = true;            # provide docker alias
      dockerSocket.enable = !cfg.harden;  # link podman socket as /var/run/docker.sock requires restart

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
