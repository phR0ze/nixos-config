# Networking options for the system
#
# ## Network model
# - systemd-networkd is always the backend. All wired config (DHCP, static IP, bridge, macvlan) is
#   written below as native `systemd.network` netdevs/networks rather than going through NixOS's
#   `networking.interfaces`/`bridges`/`macvlans` translation layer, and NixOS's legacy scripted
#   networking + dhcpcd is never used.
# - NetworkManager is an optional overlay for desktops (WiFi, tray applet, captive portals). When NM
#   is on and the host has neither a bridge nor a static IP, NM owns every interface and networkd
#   manages nothing. When the host does have a bridge or static IP, networkd owns nic0/bridge/macvlan
#   and NM is told to leave them alone, still handling WiFi and anything else.
# - systemd-resolved is the only resolver on every host. DNS mode is selected by `dns.primary`, see
#   the DNS section of the config below.
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
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.devices.network;

  # NetworkManager can also be turned on outside this module, e.g. by the ISO's installer profile
  nmEnabled = config.networking.networkmanager.enable;

  staticIp = cfg.nic0.ip != "";
  staticDns = cfg.dns.primary != "";

  # networkd owns the wired config unless NM is on and there's nothing it can't handle itself
  networkdWired = !nmEnabled || cfg.bridge.enable || staticIp;

  # Shared by every network unit below. IPv6 is disabled host-wide so don't have networkd try to
  # configure IPv6 link-local addresses.
  common = { networkConfig.LinkLocalAddressing = "no"; };

  # DHCP configuration for a link. In static DNS mode the link refuses the DHCP-provided DNS.
  dhcp = { DHCP = "ipv4"; dhcpV4Config.UseDNS = !staticDns; };

  # Static configuration for the link carrying the host's primary address
  static = ip: { address = [ ip ]; gateway = [ cfg.gateway ]; };

  # Build a network unit matching the given interface name
  network = name: attrs: lib.recursiveUpdate (lib.recursiveUpdate common { matchConfig.Name = name; }) attrs;
in
{
  options.devices.network = {
    networkManager.enable = lib.mkEnableOption ''
      NetworkManager on top of networkd for desktop WiFi, tray applet and captive portal handling
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
          Primary DNS server. Setting it selects static DNS mode: this is the only server used and
          DHCP-provided DNS is ignored on every link, regardless of network backend. Leave unset
          (e.g. on roaming laptops) for DHCP DNS mode, where each link's DHCP-provided DNS wins,
          which lets captive portals (airline wifi, hotels, etc.) resolve their own login domains
          automatically. Required when `devices.network.nic0.ip` is static, since no DHCP runs to
          provide DNS.
        '';
        type = types.str;
        example = "1.1.1.1";
        default = "";
      };

      fallback = lib.mkOption {
        description = lib.mdDoc ''
          Fallback DNS server, only used by resolved when no other DNS server is known at all i.e.
          neither `primary` nor any link's DHCP-provided DNS. Defaults to `primary` so that when
          `primary` is set, resolved can never fall back to its compiled-in public servers
          (Cloudflare/Google/Quad9) - set it explicitly to choose a different fallback.
        '';
        type = types.str;
        example = "8.8.8.8";
        default = cfg.dns.primary;
      };
    };

    bridge = {
      enable = lib.mkEnableOption ''
        converting the primary interface into a bridge which then allows virtualized devices like
        containers and VMs to join the LAN, be assigned LAN IP addresses and fully interact with
        other devices on the LAN. All of the other primary network settings will be used for the
        new bridge interface.

        Note, for bridge mode to work the primary nic must be specified via
        `devices.network.nic0.name` and the host macvlan via `devices.network.macvlan.name`
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
        description = lib.mdDoc "Macvlan IP and CIDR combination, DHCP is used when not set";
        type = types.str;
        example = "192.168.1.41/24";
        default = "";
      };

      mac = lib.mkOption {
        description = lib.mdDoc ''
          Macvlan MAC address, note the first octet must be '02'. The MAC is only applied when
          networkd creates the macvlan, so changing it on a running host needs the existing macvlan
          removed first e.g. `ip link del <macvlan.name>` followed by `networkctl reload`.
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
        description = lib.mdDoc "Primary NIC IP and CIDR combination, DHCP is used when not set";
        type = types.str;
        example = "192.168.1.41/24";
        default = "";
      };

      mapNameFromMAC = lib.mkOption {
        description = lib.mdDoc ''
          MAC address to pin this NIC's `name` to via a systemd .link file, and disable
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
        nftables rules to provide protection for per-source connection-flooding, host-wide
        geo-blocking of non-US IPv4 CIDRs, CrowdSec enforcement of suspicious behavior.
        Note: Container ports are not covered by this and need separate Traefik Crowdsec protection.
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
        { assertion = staticIp -> cfg.nic0.name != "";
          message = "devices.network.nic0.name must be specified e.g. 'eth0' when devices.network.nic0.ip is static";
        }
        { assertion = staticIp -> cfg.gateway != "";
          message = "devices.network.gateway must be specified when devices.network.nic0.ip is static";
        }
        { assertion = staticIp -> staticDns;
          message = "devices.network.dns.primary must be specified when devices.network.nic0.ip is static - no DHCP runs, so no DNS server would be learned";
        }
        { assertion = cfg.bridge.enable -> cfg.nic0.name != "";
          message = "devices.network.nic0.name must be specified e.g. 'eth0' for bridge mode";
        }
        { assertion = cfg.bridge.enable -> cfg.bridge.name != "";
          message = "devices.network.bridge.name must be specified for bridge mode";
        }
        { assertion = cfg.bridge.enable -> cfg.macvlan.name != "";
          message = "devices.network.macvlan.name must be specified for bridge mode";
        }
      ];

      # networkd is always the backend and every wired unit is declared explicitly below, so turn
      # off NixOS's generic catch-all DHCP units.
      networking.useNetworkd = true;
      networking.useDHCP = false;

      # Use modern nftables for `networking.firewall` to be compatible with crowdsec
      networking.nftables.enable = true;

      # Disable ipv6 and is related parts to be explicit
      networking.enableIPv6 = false;
      boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 0;

      networking.firewall.allowPing = true;

      # systemd-resolved is the only resolver on every host, for both networkd and NetworkManager.
      # DNS can be temporarily changed per interface with: sudo resolvectl dns enp1s0 1.1.1.1
      services.resolved = {
        enable = true;

        # Leave DNSSEC validation to the upstream resolver (e.g. AdGuard, 1.1.1.1). resolved's
        # local "allow-downgrade" mode is known to cause intermittent resolution failures with home
        # routers, filtering resolvers and VPN DNS servers, and "true" breaks outright on any of
        # them that don't support DNSSEC.
        settings.Resolve.DNSSEC = "no";
      };
    }

    # Wait for the network to come online
    # ----------------------------------------------------------------------------------------------
    # By default networkd-wait-online waits for every link networkd manages, which stalls boot and
    # `nixos-rebuild switch` for its full timeout whenever one of them isn't connected e.g. a WiFi
    # card with no network in range. Waiting for any one link is enough to reach the network. On NM
    # hosts where networkd manages nothing it would never succeed at all, and
    # NetworkManager-wait-online already covers network-online.target.
    {
      systemd.network.wait-online.anyInterface = lib.mkIf networkdWired true;
      systemd.network.wait-online.enable = lib.mkIf (!networkdWired) false;
    }

    # Configure wired networking
    # ----------------------------------------------------------------------------------------------
    # Plain DHCP on every physical ethernet and WiFi station interface, same as NixOS's own generic
    # catch-all units. On NM hosts NM handles this case itself.
    (lib.mkIf (networkdWired && !cfg.bridge.enable && !staticIp) {
      systemd.network.networks."30-wired" = lib.recursiveUpdate (lib.recursiveUpdate common dhcp) {
        matchConfig = { Type = "ether"; Kind = "!*"; };  # physical interfaces have no kind
      };

      # Prefer ethernet over WiFi when both are connected
      systemd.network.networks."30-wireless" = lib.recursiveUpdate (lib.recursiveUpdate common dhcp) {
        matchConfig.WLANInterfaceType = "station";
        dhcpV4Config.RouteMetric = 1025;
      };
    })

    # Static IP on the primary NIC
    (lib.mkIf (networkdWired && !cfg.bridge.enable && staticIp) {
      systemd.network.networks."30-${cfg.nic0.name}" = network cfg.nic0.name (static cfg.nic0.ip);
    })

    # Convert the primary NIC into a bridge carrying the host's primary address, plus a host macvlan
    # on the bridge. Otherwise the virtualized devices on the bridge can be reached by every device
    # on the LAN except the host itself.
    (lib.mkIf cfg.bridge.enable {
      devices.network.primary.name = cfg.bridge.name;

      systemd.network.netdevs."30-${cfg.bridge.name}".netdevConfig = {
        Kind = "bridge";
        Name = cfg.bridge.name;
      };
      systemd.network.networks."30-${cfg.nic0.name}" = network cfg.nic0.name {
        networkConfig.Bridge = cfg.bridge.name;
        linkConfig.RequiredForOnline = "enslaved";
      };
      systemd.network.networks."30-${cfg.bridge.name}" = network cfg.bridge.name
        ({ macvlan = [ cfg.macvlan.name ]; } // (if staticIp then static cfg.nic0.ip else dhcp));

      systemd.network.netdevs."30-${cfg.macvlan.name}" = {
        netdevConfig = {
          Kind = "macvlan";
          Name = cfg.macvlan.name;
        } // lib.optionalAttrs (cfg.macvlan.mac != "") { MACAddress = cfg.macvlan.mac; };
        macvlanConfig.Mode = "bridge";
      };
      # The bridge carries the default route, don't let a DHCP'd macvlan install a competing one
      systemd.network.networks."30-${cfg.macvlan.name}" = network cfg.macvlan.name
        (if cfg.macvlan.ip != "" then { address = [ cfg.macvlan.ip ]; }
        else lib.recursiveUpdate dhcp { dhcpV4Config.UseGateway = false; });
    })

    # Pin nic0's name by MAC and disable predictable interface naming, only when a host opts in
    # via `devices.network.nic0.mapNameFromMAC` (see modules/types/nic.nix for why this is needed).
    # Matching on the permanent MAC only matches the real hardware, never a bridge/macvlan/VLAN that
    # happens to share its MAC.
    (lib.mkIf (cfg.nic0.mapNameFromMAC != "") {
      networking.usePredictableInterfaceNames = lib.mkForce false;
      systemd.network.links."10-${cfg.nic0.name}" = {
        matchConfig.PermanentMACAddress = cfg.nic0.mapNameFromMAC;
        linkConfig.Name = cfg.nic0.name;
      };
    })

    # Configure DNS
    # ----------------------------------------------------------------------------------------------
    # DNS mode is selected by whether `primary` is set:
    # - static: `primary` becomes resolved's global nameserver and every link refuses DHCP-provided
    #   DNS. Just setting a global nameserver isn't enough - resolved queries the global servers and
    #   every link's servers in parallel and takes the first answer, so the DHCP servers have to be
    #   kept off the links entirely. networkd links refuse it via `dhcp` above, NM is stopped from
    #   passing any DNS to resolved below.
    # - DHCP: leave `primary` unset (e.g. on roaming laptops) so each link's DHCP-provided DNS wins,
    #   which lets captive portals (airline wifi, hotels, etc.) resolve their own login domains.
    #   `fallback` is only used when no link provides any DNS at all.
    (lib.mkIf staticDns (lib.mkMerge [
      { networking.nameservers = [ cfg.dns.primary ]; }

      # Also disables NM's captive portal login and any VPN-provided DNS, which is the point of
      # static mode
      (lib.mkIf nmEnabled {
        networking.networkmanager.dns = lib.mkForce "none";
      })
    ]))
    (lib.mkIf (cfg.dns.fallback != "") {
      services.resolved.settings.Resolve.FallbackDNS = [ cfg.dns.fallback ];
    })

    # Configure network manager
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf cfg.networkManager.enable {
      networking.networkmanager = {
        enable = true;                      # Enable networkmanager and nm-applet
        dns = "systemd-resolved";           # Configure systemd-resolved as the DNS provider

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

    # Keep NM off the interfaces it doesn't own: container networks, and whatever networkd owns (see
    # the network model at the top of this file). Two managers on one interface race each other for
    # addresses, routes and DNS.
    (lib.mkIf nmEnabled {
      networking.networkmanager.unmanaged = [ "interface-name:podman*" ]
        ++ lib.optionals (networkdWired && cfg.nic0.name != "") [ "interface-name:${cfg.nic0.name}" ]
        ++ lib.optionals cfg.bridge.enable [
          "interface-name:${cfg.bridge.name}"
          "interface-name:${cfg.macvlan.name}"
        ];
    })

    # Harden
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf cfg.harden.enable {
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

      # Connection-flood limiting
      # ----------------------------------------------------------------------------------------------
      # A per-source cap on new connection attempts, tracked in a dynamic set keyed on the source
      # address so one flooding source only ever throttles itself, never everyone else. Hooked at a
      # lower priority (evaluated earlier) than geoblock/CrowdSec/NixOS's own `input` chain below, so
      # a genuine flood is dropped before it costs anything further downstream. This chain only ever
      # DROPs or falls through via `policy accept`, so it can't itself let anything through that a
      # later chain would otherwise have refused. Loopback and container bridge traffic are exempt,
      # same as the geo-block below.
      # - requires kernel module `nft_limit`, preloaded by modules/devices/kernel.nix's harden block
      networking.nftables.tables.connlimit = {
        family = "ip";
        content = ''
          set connlimit-src {
            type ipv4_addr
            flags dynamic
            timeout 1m
          }

          chain connlimit-chain {
            type filter hook input priority filter - 5; policy accept;
            iifname "lo" accept
            iifname "podman*" accept
            ct state new add @connlimit-src { ip saddr limit rate over 60/second burst 120 packets } drop
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
            # AF_NETLINK (same reasoning as crowdsec-firewall-bouncer.service), and curl needs
            # AF_INET.
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
  ];
}
