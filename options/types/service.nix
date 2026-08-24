# Declares service options type for reusability
#
# For use with docker containers mainly to make it easier to wrap and deploy them
#---------------------------------------------------------------------------------------------------
{ lib, defaults, ... }: with lib.types;
{
  options = {
    enable = lib.mkEnableOption "Deploy ${defaults.name or "target"} service";

    name = lib.mkOption {
      description = lib.mdDoc "Service name. Useful for automation";
      type = types.nullOr types.str;
      default = defaults.name or null;
    };

    tag = lib.mkOption {
      description = lib.mdDoc "Service image 'tag' to use";
      type = types.str;
      default = defaults.tag or "latest";
    };

    user = lib.mkOption {
      description = lib.mdDoc "User options for service";
      type = types.nullOr (types.submodule (import ./user.nix { inherit lib; defaults = defaults.user or {}; }));
      default = defaults.user or null;
    };

    port = lib.mkOption {
      description = lib.mdDoc "Service port to use";
      type = types.int;
      default = defaults.port or 80;
    };

    subdomain = lib.mkOption {
      description = lib.mdDoc ''
        Front this service with `services.raw.caddy` at `<subdomain>.<domain>`. Leave `null` to not
        expose it via Caddy.
      '';
      type = types.nullOr types.str;
      default = defaults.subdomain or null;
    };

    # Fixed subnet/IP rather than netavark's auto-IPAM. Podman/netavark have a long-standing bug
    # (containers/podman#27516, containers/netavark#302) where the hostport DNAT rule for a
    # stopped container is never removed — a new rule is just appended on every restart, and the
    # stale one (pointing at a dead container IP) wins because nftables evaluates in insertion
    # order. Auto-IPAM compounds this: if the network itself ever gets recreated (not just the
    # container), it can land on a *different* subnet than before, leaving the host bridge
    # interface holding a stale address for a subnet nothing routes to anymore (this is what took
    # oneup.farspire.io down). Pinning `subnet` keeps the network's addressing stable across
    # recreation; pinning `ip` makes a leftover stale rule harmless even when netavark fails to
    # clean it up, since it ends up identical to the live one instead of pointing at a dead
    # address. See `funcs/service.nix`'s `createContNetwork`/`hostInSubnet`.
    subnet = lib.mkOption {
      description = lib.mdDoc "Fixed CIDR (e.g. `10.89.101.0/24`) for this service's isolated podman network";
      type = types.nullOr types.str;
      default = defaults.subnet or null;
    };

    ip = lib.mkOption {
      description = lib.mdDoc "Fixed IP address (within `subnet`) for this service's container";
      type = types.nullOr types.str;
      default = defaults.ip or null;
    };

    # Shared container-hardening fields, matching the baseline Newt already runs with (see
    # `newt.nix`): cap-drop=ALL, no-new-privileges, read-only rootfs. All default to `false` — a
    # no-op for any module that doesn't opt in — because none of them are safe to flip on blind.
    # In particular, any app whose entrypoint runs as root and drops privileges itself via
    # PUID/PGID (Homarr, Stirling-PDF — search for that pattern before enabling these there) needs
    # capabilities like CAP_CHOWN/CAP_SETUID/CAP_SETGID during that startup dance, and often writes
    # to its own rootfs at boot (Stirling-PDF re-downloads its jar every start) — cap-drop=ALL or
    # read-only would break that the same way this session's systemd sandboxing broke podman's own
    # internals, just one layer down (container capabilities instead of the host unit). Only safe
    # to enable for a service that already runs as a fixed non-root `user = "uid:gid"` with no
    # startup-time chown/setuid step of its own — verify per-module before flipping any of these on.
    capDropAll = lib.mkOption {
      description = lib.mdDoc ''
        Run the container with `--cap-drop=ALL`. Only safe for a service that never needs a Linux
        capability at runtime — verify the image doesn't do its own root-then-drop-privileges
        startup dance (PUID/PGID-style entrypoints) before enabling.
      '';
      type = types.bool;
      default = defaults.capDropAll or false;
    };

    noNewPrivileges = lib.mkOption {
      description = lib.mdDoc "Run the container with `--security-opt=no-new-privileges`.";
      type = types.bool;
      default = defaults.noNewPrivileges or false;
    };

    readOnlyRootfs = lib.mkOption {
      description = lib.mdDoc ''
        Run the container with `--read-only` plus a small writable `/tmp` tmpfs. Only safe for a
        service that never writes outside its declared `volumes` at runtime — verify the image
        doesn't download/generate anything into its own rootfs at startup before enabling.
      '';
      type = types.bool;
      default = defaults.readOnlyRootfs or false;
    };
  };
}
