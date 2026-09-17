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
{ config, lib, f, ... }: with lib.types;
let
  cfg = config.devices.network;
in
{
  options.devices.network = {
    harden = lib.mkEnableOption "Apply recommended networking hardening";

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

      networking.enableIPv6 = false;
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
    (lib.mkIf (cfg.harden) {
      networking.domain = "";                             # always require fully-qualified names

      networking.firewall.allowPing = lib.mkForce false;   # don't respond to pings

      # Log refused/dropped TCP connection attempts (kernel LOG target) so a port-scan detector
      # (e.g. CrowdSec's iptables/nftables collection) has something to work from - without this,
      # anything that isn't caught by a service's own logs (e.g. sshd auth attempts) is invisible.
      networking.firewall.logRefusedConnections = true;

      # nftables replaces the legacy iptables/ipset backend for both `networking.firewall` itself
      # and (via services.crowdsec-firewall-bouncer's own `mode` default, which derives from this
      # same flag) the CrowdSec bouncer - see modules/services/native/crowdsec.nix, which sheds its
      # ip_set/xt_set kernel modules and CAP_NET_RAW once this is on.
      networking.nftables.enable = true;
    })

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
      networking.interfaces."${cfg.nic0.name}".ipv4.addresses = [ (f.toIP cfg.nic0.ip) ];
    }))

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
