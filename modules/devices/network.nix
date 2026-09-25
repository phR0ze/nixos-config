# Networking options for the system
#
# ## Container networking
# Networking options for connecting containers needs to be carefully planned:
# - For protection against supply chain attacks and bad actors every container should be deployed in
#   its own isolated user-defined docker network in bridge mode.
# - Deploy a reverse proxy e.g. Caddy on an additional user-defined docker network in bridge mode and
#   then connect Caddy to each of the isolatec container networks
# - Expose (i.e. map) ports 80/443 from Caddy to the host and configure Caddy to then act as the
#   reverser proxy for any of the applications that you'd like to expose to the LAN
#
# ### Failed options
# - Dedicated macvlans with static IPs on the host for each app hypothetically would have worked but
#   in practice became unwieldy and seemed to frequently confuse the networking stack i.e. didn't
#   work. Additionally macvlan changes required a networking stack restart which was distruptive and
#   an additional macvlan for the host to be able to communicate with the apps.
# - Docker macvlans for each app though more stable doesn't provide protection from bad actors
# - Exposing apps directly on the host provides isolation but becomes unwieldy and difficult to
#   juggle all the various port mappings.
#---------------------------------------------------------------------------------------------------
{ config, lib, f, pkgs, ... }: with lib.types;
let
  cfg = config.devices.network;
in
{
  options.devices.network = {
    networkManager.enable = lib.mkEnableOption "Install and configure network manager";

    networkd.enable = lib.mkEnableOption ''
      systemd-networkd as the network backend instead of the legacy scripted networking module.
      NixOS auto-translates the nic0/bridge/macvlan/gateway config below into networkd .network/
      .netdev units - nothing else in this module needs to change to support it. Mutually
      exclusive with NetworkManager (devices.network.networkManager.enable) - pick one backend per
      host.
    '';

    gateway = lib.mkOption {
      description = lib.mdDoc "Default gateway to use for the host, required when devices.network.nic0.ip is static";
      type = types.str;
      example = "192.168.1.1";
      default = "";
    };

    subnet = lib.mkOption {
      description = lib.mdDoc "Default subnet/CIDR to use for the host";
      type = types.str;
      example = "192.168.1.0/24";
      default = "";
    };

    dns = {
      primary = lib.mkOption {
        description = lib.mdDoc ''
          Primary DNS server. Forces a global nameserver, overriding whatever DHCP hands out on
          every link. Leave unset (e.g. on roaming laptops) so DHCP-provided per-link DNS always
          wins, which lets captive portals (airline wifi, hotels, etc.) resolve their own login
          domains automatically.
        '';
        type = types.str;
        example = "1.1.1.1";
        default = "";
      };

      fallback = lib.mkOption {
        description = lib.mdDoc ''
          Fallback DNS server, only used by resolved when a link provides no DNS at all. Safe to
          set even when `primary` is unset.
        '';
        type = types.str;
        example = "8.8.8.8";
        default = "";
      };

      force = lib.mkEnableOption ''
        forcing the global DNS nameservers to be used, ignoring whatever DNS any link is separately
        handed. Off by default since this breaks NetworkManager's captive portal detection/login,
        which relies on DHCP-provided per-link DNS
      '';
    };

    bridge = {
      enable = lib.mkEnableOption ''
        converting the primary interface into a bridge which then allows virtualized devices like
        containers and VMs to join the LAN, be assigned LAN IP addresses and fully interact with
        other devices on the LAN. All of the other primary network settings will be used for the
        new bridge interface.

        Note, for bridge mode to work the primary nic must be specified via `devices.network.nic0.name`
      '';

      name = lib.mkOption {
        description = lib.mdDoc "Name to use for the new bridge";
        type = types.str;
        default = "br0";
      };
    };

    macvlan = {
      name = lib.mkOption {
        description = lib.mdDoc ''
          Macvlan interface name for the host to use on the bridge, which allows the host to
          communicate with virtualized devices connected to the bridge. Otherwise the virtualized
          devices can fully participate on the LAN but the host won't be able to interact directly
          with them.
        '';
        type = types.str;
        default = "";
      };

      ip = lib.mkOption {
        description = lib.mdDoc "Macvlan IP and CIDR combination";
        type = types.str;
        example = "192.168.1.41/24";
        default = "";
      };

      mac = lib.mkOption {
        description = lib.mdDoc ''
          Macvlan MAC address, note the first octet must be '02'. Gets set on creation, so a
          change might need `ip link del <macvlan.name>` and then a rerun to take effect.
        '';
        type = types.str;
        default = "";
      };
    };

    nic0 = {
      name = lib.mkOption {
        description = lib.mdDoc ''
          Primary NIC identifier in the system, typically a physical interface name like 'eth0',
          'eno1' or 'enp1s0'.
        '';
        type = types.str;
        example = "eth0";
        default = "";
      };

      ip = lib.mkOption {
        description = lib.mdDoc "Primary NIC IP and CIDR combination";
        type = types.str;
        example = "192.168.1.41/24";
        default = "";
      };

      mapNameFromMAC = lib.mkOption {
        description = lib.mdDoc ''
          MAC address to pin this NIC's `name` to via a udev rule, and disable
          `networking.usePredictableInterfaceNames` for. Needed on hosts (e.g. some cloud/VPS
          providers' virtio NICs) where the kernel's predictable name (`enp0s3`, `ens3`, ...) won't
          match a hardcoded `name` like "eth0" used elsewhere in this host's static config -
          pinning by MAC keeps the name deterministic without predictable naming's bus-topology
          dependency. Leave unset (default) on hosts where predictable naming already matches, or
          where the interface name isn't hardcoded anywhere.
        '';
        type = types.str;
        example = "00:11:22:33:44:55";
        default = "";
      };
    };

    primary.name = lib.mkOption {
      description = lib.mdDoc ''
        Primary interface to use for network access. This will typically just be the physical nic
        e.g. ens18, but when 'devices.network.bridge.enable = true' it will be set to
        'devices.network.bridge.name' e.g. br0 as the bridge will be the primary interface.
      '';
      type = types.str;
      default = cfg.nic0.name;
    };

    primary.ip = lib.mkOption {
      description = lib.mdDoc "Primary interface IP in CIDR notation";
      type = types.str;
      example = "192.168.1.50/24";
      default = cfg.nic0.ip;
    };

    harden = {
      enable = lib.mkEnableOption ''
        recommended networking hardening. This also turns on a host-wide inbound geo-block: drops
        every NEW, externally-initiated connection whose source address isn't inside a
        US-registered IPv4 CIDR block (per the daily CI-published `ipverse/country-ip-blocks`
        aggregate), regardless of destination port - any future opened port is automatically
        covered without touching this module again. Only conntrack state NEW packets are ever
        evaluated, so outbound-initiated traffic and its return path (nix substituter fetches from
        cache.nixos.org, sops key fetches, CrowdSec's own hub/LAPI polling, DNS, NTP - none of
        which are guaranteed to be US-hosted) are unaffected.

        Implemented as its own nftables table, mirroring exactly how
        `services.crowdsec-firewall-bouncer` structures its own `crowdsec` table: a declarative,
        NixOS-managed table+chain+empty-set skeleton (loaded once by nftables.service), with the
        set's actual contents refreshed independently at runtime by a small systemd timer - not a
        separate firewall backend, and not competing with CrowdSec's own table for the same hook
        (see the module-level comment on the config block below for why coexistence is safe).
      '';

      geoblockAllowList = lib.mkOption {
        description = lib.mdDoc ''
          CIDRs/IPs that always bypass the geo-filter regardless of country, mirroring
          `services.native.crowdsec.allowlist`'s purpose: a safety valve against a self-inflicted
          lockout if the upstream geoIP data is ever wrong, or the admin travels/tunnels through a
          non-US VPN exit. Baked directly into the declarative table's initial set contents (loaded
          synchronously by nftables.service at boot, zero network dependency, zero delay) and
          re-applied on every subsequent daily refresh alongside the fetched US list.
        '';
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "203.0.113.7" "198.51.100.0/24" ];
      };
    };
  };

  config = lib.mkMerge [

    # Configure basic networking
    # ----------------------------------------------------------------------------------------------
    {
      assertions = [
        {
          assertion = !(cfg.networkManager.enable && cfg.networkd.enable);
          message = "devices.network.networkManager.enable and devices.network.networkd.enable are mutually exclusive - pick one network backend";
        }
      ];

      # Use modern nftables for `networking.firewall` to be compatible with crowdsec
      networking.nftables.enable = true;

      # Disable ipv6 and is related parts to be explicit
      networking.enableIPv6 = false;
      boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 0;

      networking.firewall.allowPing = true;
      networking.useNetworkd = cfg.networkd.enable;
    }

    # Configure global DNS. resolved works well with network manager
    # DNS can be temporarily changed per interface with: sudo resolvectl dns enp1s0 1.1.1.1
    # ----------------------------------------------------------------------------------------------
    {
      services.resolved = {
        enable = true;
        settings.Resolve.DNSSEC = "allow-downgrade"; # using "true" will break DNS if VPN DNS servers don't support
      };
    }

    # Primary and fallback DNS are configured independently:
    # - `primary` forces a global nameserver, overriding whatever DHCP hands out on every link. Leave
    #   it unset (e.g. on roaming laptops) so DHCP-provided per-link DNS always wins, which lets
    #   captive portals (airline wifi, hotels, etc.) resolve their own login domains automatically.
    # - `fallback` is only used by resolved when a link provides no DNS at all, so it's safe to set
    #   even when `primary` is unset.
    (lib.mkIf (cfg.dns.primary != "") {
      networking.nameservers = [ "${cfg.dns.primary}" ];

      # Force the global dns nameservers to be used, ignoring whatever DNS any link is separately
      # handed. Off by default since this breaks NetworkManager's captive portal detection/login,
      # which relies on DHCP-provided per-link DNS.
      services.resolved.settings.Resolve.Domains = lib.mkIf cfg.dns.force [ "~." ];
    })
    (lib.mkIf (cfg.dns.fallback != "") {
      services.resolved.settings.Resolve.FallbackDNS = [ "${cfg.dns.fallback}" ];
    })

    # Harden
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.harden.enable) {
      networking.domain = "";                             # always require fully-qualified names

      networking.firewall.allowPing = lib.mkForce false;   # don't respond to pings

      # Log refused/dropped TCP connection attempts (kernel LOG target) so a port-scan detector
      # (e.g. CrowdSec's iptables/nftables collection) has something to work from - without this,
      # anything that isn't caught by a service's own logs (e.g. sshd auth attempts) is invisible.
      networking.firewall.logRefusedConnections = true;

      # LLMNR/mDNS are same-subnet discovery protocols (resolving other local devices' hostnames
      # without a DNS server) - meaningless on a host with no local peers to discover, and the
      # firewall already drops them from outside regardless, so this is just shedding unneeded
      # listeners rather than closing an active exposure.
      services.resolved.settings.Resolve.LLMNR = "no";
      services.resolved.settings.Resolve.MulticastDNS = "no";
    })

    # Connection-flood limiting
    # ----------------------------------------------------------------------------------------------
    # A blanket per-source cap on new connection attempts, hooked at a lower priority (evaluated
    # earlier) than geoblock/CrowdSec/NixOS's own `input` chain below, so a genuine flood is dropped
    # before it costs anything further downstream - geoblock's set lookup, CrowdSec's bouncer chain,
    # and (most relevantly for CPU/IO under load) the `logRefusedConnections` log line every refused
    # packet otherwise generates in NixOS's own `input` chain. 60/sec burst 120 is far above any
    # legitimate traffic this single-admin VPS sees, so normal use (including a scan burst small
    # enough for CrowdSec to still characterize and ban) is unaffected - only flood-level volume gets
    # capped here. Same coexistence reasoning as geoblock below: this chain only ever DROPs or falls
    # through via `policy accept`, so it can't itself let anything through that a later chain would
    # otherwise have refused.
    (lib.mkIf (cfg.harden.enable) {
      # This chain's `limit rate` expression needs its own kernel module (nft_limit), distinct
      # from nf_tables itself - both preloaded centrally by modules/devices/kernel.nix's harden
      # block (see its comment for the module-lock ordering and why it's gathered there).
      networking.nftables.tables.connlimit = {
        family = "ip";
        content = ''
          chain connlimit-chain {
            type filter hook input priority filter - 5; policy accept;
            iifname "lo" accept
            ct state new limit rate 60/second burst 120 packets accept
            ct state new drop
          }
        '';
      };
    })

    # Geo-block
    # ----------------------------------------------------------------------------------------------
    # Mirrors services.native.crowdsec's own nftables integration pattern (see that module and its
    # upstream nixos/modules/services/security/crowdsec-firewall-bouncer.nix for the precedent this
    # follows): a declarative table+chain+set skeleton, loaded once by the stock nftables.service,
    # with the set's actual membership refreshed independently at runtime - decoupled from the
    # declarative ruleset's own reload cycle, so a daily CIDR-list refresh never needs a
    # `nixos-rebuild switch` and never risks a full nftables.service ruleset reload interrupting
    # traffic on an unrelated table (CrowdSec's, or NixOS's own generated firewall chain).
    #
    # Coexistence with CrowdSec's `crowdsec-chain` (same `input` hook, same `filter` priority
    # neighborhood) is safe because neither chain ever independently ACCEPTs a packet - each can
    # only DROP (final, immediate) or fall through via its own `policy accept` (provisional only:
    # the packet still traverses every other base chain hooked to `input`, including NixOS's own
    # generated firewall chain, before actually being allowed through). So a packet is let through
    # only if NONE of the input-hooked chains drop it, regardless of which one nftables happens to
    # evaluate first - this holds structurally, not by careful ordering, which is why this table
    # doesn't need any systemd-level ordering dependency against crowdsec-firewall-bouncer.service
    # for correctness. `hook input priority filter + 5` (rather than bare `filter`, which CrowdSec's
    # own table already uses) only exists for predictable/readable `nft list ruleset` output during
    # debugging - it has no effect on the actual drop-or-defer semantics above.
    (lib.mkIf (cfg.harden.enable) (
      let
        usCidrUrl = "https://raw.githubusercontent.com/ipverse/country-ip-blocks/master/country/us/ipv4-aggregated.txt";
        extraElements = lib.concatStringsSep ", " cfg.harden.geoblockAllowList;
      in
      {
        assertions = [
          {
            assertion = config.networking.nftables.enable;
            message = "devices.network.harden.enable requires networking.nftables.enable - the geo-block it applies is nftables-only.";
          }
        ];

        # Same nf_tables module services.native.crowdsec.nix and the connlimit chain above also
        # need - preloaded centrally by modules/devices/kernel.nix's harden block, see its comment
        # for the module-lock interaction and why it's gathered there rather than duplicated here.

        # Declarative skeleton: table/chain/set structure only, loaded once by nftables.service.
        # geoblockAllowList is baked in as the set's initial elements - loaded synchronously at
        # boot with zero network dependency, unlike the fetched US list (which needs
        # geoblock-refresh to have run at least once). This closes the "boot to first-refresh"
        # safety-valve gap entirely, not just narrows it: a geoblockAllowList-listed admin can
        # always get in, even in the window before the first daily refresh completes.
        networking.nftables.tables.geoblock = {
          family = "ip";
          content = ''
            set geoblock-allow {
              type ipv4_addr
              # auto-merge is required, not just tidy: a geoblockAllowList /32 that happens to fall
              # inside a CIDR the fetched US list also carries is a same-batch overlap, and plain
              # `flags interval` rejects that as "conflicting intervals specified" (confirmed via a
              # live vps1 refresh failure where the allowlist IP nested inside a US block). auto-merge
              # collapses such overlaps instead of erroring, which is what we want either way.
              flags interval
              auto-merge
              ${lib.optionalString (cfg.harden.geoblockAllowList != [ ]) "elements = { ${extraElements} }"}
            }

            chain geoblock-chain {
              type filter hook input priority filter + 5; policy accept;
              # 127.0.0.0/8 is never inside the fetched US CIDR set, so without this exception
              # every loopback-addressed connection on the host - including CrowdSec's own agent
              # talking to its local API on 127.0.0.1:8080 - gets geo-filtered out (confirmed via
              # a local quickemu VM test: crowdsec.service failed outright with "dial tcp
              # 127.0.0.1:8080: i/o timeout" the moment this chain went live). The original
              # iptables-era design had an explicit "-i lo -j RETURN" for the same reason - this is
              # that same exception, just expressed as an nftables interface match.
              iifname "lo" accept
              # Same reasoning as the `lo` exception above, for container bridge traffic instead of
              # loopback: geo-blocking is meant to filter *internet-facing* new connections, not
              # traffic a container sends to a host-local service over its own bridge (e.g. the
              # containerized pangolin stack's crowdsec container resolving DNS via aardvark-dns on
              # the podman1 bridge's own address). Without this, every such request is a "new"
              # connection whose source (the container's bridge-subnet IP) is never inside the
              # fetched US CIDR set, so it gets dropped exactly like the undocumented `lo` case above
              # - confirmed live via nftables packet tracing: ICMP/UDP/TCP from a container's netns
              # to its own gateway IP was silently dropped here, while forwarded traffic to external
              # IPs passed fine (hosts/vm-vps1 testing, 2026-09-21). Matches nixos-fw's own
              # `iifname "podman*" udp dport 53 accept` wildcard for the same interface family.
              iifname "podman*" accept
              ct state new ip saddr != @geoblock-allow drop
            }
          '';
        };

        # Recurring refresh of the SET'S CONTENTS only - never touches the declarative table/chain
        # above. `nft -f` applies every statement in one invocation as a single atomic kernel
        # transaction (nftables' own core guarantee, unlike iptables-legacy's line-by-line
        # non-transactional model): if any element fails to parse, NONE of the statements take
        # effect and the live set is left completely untouched. Combined with `set -e` +
        # `curl --fail` aborting the whole script before ever invoking `nft -f` on a failed fetch,
        # a failed refresh always fails safe - it falls back to yesterday's still-reasonably-fresh
        # list rather than wiping the set to empty or loading a truncated/garbage one.
        systemd.services.geoblock-refresh = {
          description = "Fetch the current US IPv4 CIDR list and atomically refresh the geoblock nftables set";
          after = [ "network-online.target" "nftables.service" ];
          wants = [ "network-online.target" ];
          requires = [ "nftables.service" ];
          path = [ pkgs.nftables pkgs.curl pkgs.gnugrep ];
          script = ''
            set -euo pipefail

            usCidrs=$(curl --fail --silent --show-error "${usCidrUrl}" \
              | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$' \
              | paste -sd, -)

            {
              echo "flush set ip geoblock geoblock-allow"
              echo "add element ip geoblock geoblock-allow { ${extraElements}${lib.optionalString (cfg.harden.geoblockAllowList != [ ]) ","} $usCidrs }"
            } | nft -f -
          '';
          serviceConfig = {
            Type = "oneshot";
            NoNewPrivileges = true;
            CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];   # same as crowdsec-firewall-bouncer.service's nftables-mode capability
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            ProtectKernelTunables = true;
            ProtectKernelLogs = true;
            ProtectControlGroups = true;
            ProtectClock = true;
            ProtectHostname = true;
            RestrictSUIDSGID = true;
            LockPersonality = true;
            RestrictRealtime = true;
            # RestrictAddressFamilies intentionally left unset: nft talks to the kernel over
            # AF_NETLINK (same reasoning as crowdsec-firewall-bouncer.service and sshd's own
            # AF_NETLINK allowance this session), and curl needs AF_INET.
          };
        };

        systemd.timers.geoblock-refresh = {
          description = "Daily refresh of the geoblock US IPv4 allow-set";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "2min";       # minimize the geoblockAllowList-only window after boot
            OnUnitActiveSec = "1d";   # matches ipverse/country-ip-blocks' own daily CI cadence
            RandomizedDelaySec = 300; # politeness jitter, matches crowdsec-update-hub.timer's own pattern in this repo
            Persistent = true;        # catch up if the host was off past a scheduled run
          };
        };
      }
    ))

    # Configure network manager
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.networkManager.enable) {
      # NetworkManager runs its own internal DHCP client. Leaving the legacy scripted-networking
      # dhcpcd client enabled at the same time means both independently DHCP the same interface and
      # can race to register their own (possibly differing) DNS servers with resolved - dhcpcd was
      # found doing exactly this even after NetworkManager's DNS integration was disabled.
      networking.useDHCP = false;

      networking.networkmanager = {
        enable = true;                      # Enable networkmanager and nm-applet
        dns = "systemd-resolved";           # Configure systemd-resolved as the DNS provider
        unmanaged = [                       # Ignore virtualization networks
          "interface-name:podman*"
        ];

        wifi = {
          # Disable WiFi power saving to prevent intermittent disconnections. NetworkManager's default
          # powersave mode (2/enabled) causes adapters — especially Intel iwlwifi — to aggressively
          # enter low-power states between bursts of activity, resulting in dropped connections and
          # latency spikes.
          powersave = false;
        };
      };

      # Disable WiFi power saving at the kernel module level as a second line of defense. Some drivers
      # (e.g. iwlwifi) manage their own power state independently of NetworkManager and must be
      # explicitly told not to power save via a modprobe option. This complements the NetworkManager
      # setting above and ensures coverage across Intel, Realtek, and Broadcom drivers.
      boot.extraModprobeConfig = ''
        options iwlwifi power_save=0
      '';

      # Enables ability for user to make network manager changes
      secret.users."admin".extraGroups = [ "networkmanager" ];
    })

    (lib.mkIf (cfg.bridge.enable) {
      devices.network.primary.name = cfg.bridge.name;
    })

    # Configure network bridge
    # ----------------------------------------------------------------------------------------------
    (f.mkIfElse (cfg.bridge.enable) (lib.mkMerge [

      # Create the bridge interface
      {
        assertions = [
          { assertion = (cfg.bridge.name != ""); message = "Bridge name must be specified for bridge mode"; }
          { assertion = (cfg.nic0.name != ""); message = "Primary nic must be specified e.g. 'eth0'"; }
        ];
        networking.useDHCP = false;
        networking.bridges."${cfg.bridge.name}".interfaces = ["${cfg.nic0.name}" ];
      }

      # Configure bridge for static IP or DHCP
      (f.mkIfElse (cfg.nic0.ip != "") {
        networking.interfaces."${cfg.bridge.name}".ipv4.addresses = [ (f.toIP cfg.nic0.ip) ];
      } {
        networking.interfaces."${cfg.bridge.name}".useDHCP = true;
      })

      # Create host macvlan to communicate with containers on bridge otherwise the containers can be
      # interacted with by every device on the LAN except the host due to local virtual networking oddities
      {
        assertions = [
          { assertion = (cfg.macvlan.name != ""); message = "Macvlan name must be specified"; }
        ];
        networking.macvlans."${cfg.macvlan.name}" = {
          interface = "${cfg.bridge.name}";
          mode = "bridge";
        };
      }
      (f.mkIfElse (cfg.macvlan.ip != "") {
        networking.interfaces."${cfg.macvlan.name}".ipv4.addresses = [ (f.toIP cfg.macvlan.ip) ];
      } {
        networking.interfaces."${cfg.macvlan.name}".useDHCP = true;
      })
      # optionally set the MAC address of the macvlan, note the first octet must be '02'
      # - the MAC gets set on creation so might need to `ip link del host` and then rerun update
      # - doesn't seem to work but doesn't fail either???
      (lib.mkIf (cfg.macvlan.mac != "") {
        networking.interfaces."${cfg.macvlan.name}".macAddress = cfg.macvlan.mac;
      })

    # Otherwise configure primary NIC with static IP
    # ----------------------------------------------------------------------------------------------
    ]) (lib.mkIf (cfg.nic0.ip != "") {
      assertions = [
        { assertion = (cfg.nic0.name != ""); message = "Primary nic must be specified e.g. 'eth0'"; }
      ];
      # Same reasoning as the bridge/networkManager branches above: without this, NixOS's global
      # default still runs dhcpcd against every interface lacking its own explicit DHCP setting,
      # including this statically-addressed one - it just spins probing forever, doing nothing but
      # burning a process and parsing untrusted DHCP responses off the wire.
      networking.useDHCP = false;
      networking.interfaces."${cfg.nic0.name}".ipv4.addresses = [ (f.toIP cfg.nic0.ip) ];
    }))

    # Pin nic0's name by MAC and disable predictable interface naming, only when a host opts in
    # via `devices.network.nic0.mapNameFromMAC` (see modules/types/nic.nix for why this is needed).
    (lib.mkIf (cfg.nic0.mapNameFromMAC != "") {
      networking.usePredictableInterfaceNames = lib.mkForce false;
      services.udev.extraRules = ''
        ATTR{address}=="${cfg.nic0.mapNameFromMAC}", NAME="${cfg.nic0.name}"
      '';
    })

    # Configure the default gateway if the primary nic is static
    # Under systemd-networkd the interface must be explicit - a bare string coerces to
    # `{ address = ...; interface = null; }`, which networkd's module asserts against.
    (lib.mkIf (cfg.nic0.ip != "") {
      assertions = [
        { assertion = (cfg.gateway != ""); message = "Default gateway was not specified"; }
      ];
      networking.defaultGateway = if cfg.networkd.enable
        then { address = cfg.gateway; interface = if cfg.bridge.enable then cfg.bridge.name else cfg.nic0.name; }
        else cfg.gateway;
    })
  ];
}
