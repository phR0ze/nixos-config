# Service management functions
#---------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }: {

  # Compute the Nth host address within a service's `/24` subnet e.g.
  # `hostInSubnet "10.89.107.0/24" 3` -> "10.89.107.3". Used for a multi-container service (like
  # Immich) where every container shares one `cfg.subnet` but needs its own fixed `cfg.ip`-style
  # address — see `cfg.ip`'s description in `options/types/service.nix` for why it's fixed at all.
  #-------------------------------------------------------------------------------------------------
  hostInSubnet = subnet: host: "${lib.removeSuffix "0/24" subnet}${toString host}";

  # Extract the target service and process defaults
  # - args: is the json input used by the machine and related types
  # - name: the target service's name used for user name and group
  #
  # There's no built-in uid default here — the machine's configuration.nix is the single place
  # `services.oci.<name>.user.uid` gets set (service_base.nix asserts it's present). The group id
  # always mirrors the user id (see options/types/user.nix), so there's no separate gid to set.
  #-------------------------------------------------------------------------------------------------
  getService = args: name: let
    target = args.services.oci."${name}" or {};
    service = {
      enable = target.enable or false;
      name = target.name or name;
      tag = if ((target.tag or "") != "") then target.tag else "latest";
      user = {
        name = target.user.name or name;
        group = target.user.group or name;
        pass = target.user.pass;
        fullname = target.user.fullname or name;
        email = target.user.email or "${name}@local";
        uid = target.user.uid or null;
      };
      port = target.port or 80;
      subnet = target.subnet or null;
      ip = target.ip or null;
    };
  in service;

  # Create a user for a containerized application to use. This is useful for setting the permissions 
  # on the /var/lib/APP directory to something that can be read by the container user.
  # - user: user object of the form { name; group; uid; gid }
  #-------------------------------------------------------------------------------------------------
  createUser = user: {
    name = user.name;
    isNormalUser = true;
    uid = user.uid;
    group = user.group;

    # Assign the app user space to use, defaults to 0700 permission
    home = "/var/lib/${user.name}";
    createHome = true;
  };

  # Create a group for a containerized application to use. This is useful for setting the permissions 
  # on the /var/lib/APP directory to something that can be read by the container user.
  # - user: user object of the form { name; group; uid; gid }
  createGroup = user: {
    gid = user.gid;
  };

  # Create systemd service for podman network creation
  # - name: name of the network to create e.g. `immich`
  # - subnet: fixed CIDR for this network e.g. `10.89.101.0/24` (gateway defaults to the .1 address)
  #
  # Pinned rather than left to netavark's auto-IPAM. Podman/netavark have a long-standing bug
  # (containers/podman#27516, containers/netavark#302) where the hostport DNAT rule for a stopped
  # container is never removed — a new rule is just appended on every restart, and the stale one
  # (pointing at a dead container IP) wins because nftables evaluates in insertion order. Auto-IPAM
  # compounds this: if the network itself ever gets recreated (not just the container), it can land
  # on a *different* subnet than before, leaving the host bridge interface holding a stale address
  # for a subnet nothing routes to anymore (this is what took oneup.farspire.io down). Pinning the
  # subnet keeps the network's addressing stable across recreation; pinning each container's own IP
  # (see the `--ip=` extraOptions in each services.oci.* module) makes the leftover stale rule
  # harmless even when netavark fails to clean it up, since it ends up identical to the live one
  # instead of pointing at a dead address.
  #-------------------------------------------------------------------------------------------------
  createContNetwork = { name, subnet }: {
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = [
        "${pkgs.podman}/bin/podman network rm -f ${name}"
      ];
    };
    script = ''
      if ! ${pkgs.podman}/bin/podman network exists ${name}; then
        ${pkgs.podman}/bin/podman network create --interface-name ${name} --subnet ${subnet} ${name}
      fi
    '';
  };

  # Extend systemd service for podman app service. By using the same name as the originally generated 
  # systemd service by the `oci-container` directive we can simply include more configuration for 
  # that service such as the dependency on the podman network it is to use.
  # - name: name of the podman-SUFFIX to use
  # - deps: an optional argument that when given are additional dependency services
  #-------------------------------------------------------------------------------------------------
  extendContService = { name, deps ? null }: {

    # Don't start this container unless the required services start
    requires = [
      "podman-network-${name}.service"
    ] ++ lib.optionals (deps != null) (map (x: "podman-${name}-${x}.service") deps);

    # Only start this container after these services
    after = [
      "podman-network-${name}.service"
    ] ++ lib.optionals (deps != null) (map (x: "podman-${name}-${x}.service") deps);

    serviceConfig = {
      Restart = lib.mkForce "always";
      WorkingDirectory = "/var/lib/${name}";

      # Defense-in-depth systemd sandboxing for the `podman run` wrapper process itself (on top of
      # whatever isolation the container already has). Every host-side volume mount across
      # `services/oci/*.nix` lives under `/var/lib/<name>` (already covered by `WorkingDirectory`
      # above) or is a read-only `/etc/localtime` bind — neither is affected by the restrictions
      # below, so this is safe to apply uniformly rather than per-service.
      # NOT NoNewPrivileges — rootful podman runs crun as root, then setresuid()s down to each
      # container's configured non-root user (newt/immich/oneup all set `user = "<uid>:<gid>"`).
      # That drop needs crun to retain CAP_SETUID/CAP_SETGID through the transition, which
      # NoNewPrivileges on the wrapping systemd unit blocks — `crun: setresuid to \`2002\`:
      # Operation not permitted` on every container that runs as non-root until this was reverted.
      # NOT ProtectHostname — it blocks the sethostname syscall for the whole unit, including
      # `crun` setting the container's own hostname inside its own private UTS namespace (every
      # services.oci.* container sets `hostname = ...`). That's not a host-hostname change being
      # blocked, it's normal container setup: `crun: sethostname: Operation not permitted` on every
      # single container until this was reverted.
      ProtectClock = true;
      ProtectKernelLogs = true;
      # NOT ProtectKernelTunables — podman's netavark backend writes per-interface sysctls
      # (net.ipv4.conf.<iface>.route_localnet, arp_notify, etc.) under /proc/sys every time it
      # creates a container's network namespace. Blocking that isn't hardening against a threat
      # the container poses to the host, it's blocking podman's own normal container-network
      # setup — every services.oci.* container failed to start with this enabled (learned the
      # hard way: oneup.farspire.io went down with `IO error: Read-only file system` from
      # netavark until this was reverted).
      ProtectKernelModules = true;
      # NOT RestrictSUIDSGID — unconfirmed, but a real suspect: podman extracts image layers as
      # root and preserves each file's mode bits from the tar, including the setuid/setgid bit on
      # binaries some base images ship (e.g. Debian/Ubuntu-derived images' /usr/bin/sudo, /bin/su).
      # Blocking the chmod that sets those bits risks failing layer extraction the same way
      # ProtectKernelTunables/ProtectHostname just broke sysctls/sethostname above — pulled out
      # before hitting that as a third live outage rather than after.
      LockPersonality = true;
      RestrictRealtime = true;
      ProtectHome = true;
      PrivateTmp = true;
      # "full" (not "strict") — read-only /usr, /boot, /etc, but leaves /var and /run writable.
      # "strict" would also lock down /var, breaking podman's own state dir
      # (/var/lib/containers) and every service's /var/lib/<name> data dir.
      ProtectSystem = "full";
    };
  };
}
