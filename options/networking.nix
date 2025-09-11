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
{ config, lib, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;
  networking = config.networking;
in
{
  options = {
    net.network-manager = {
      enable = lib.mkEnableOption "Install and configure network manager";
    };
    net.primary.name = lib.mkOption {
      description = lib.mdDoc ''
        Primary interface to use for network access. This will typically just be the physical nic 
        e.g. ens18, but when 'machine.net.bridge.enable = true' it will be set to 
        'machine.net.bridge.name' e.g. br0 as the bridge will be the primary interface.
      '';
      type = types.str;
      default = machine.net.nic0.name or "";
    };
    net.primary.ip = lib.mkOption {
      description = lib.mdDoc "Primary interface IP in CIDR notation";
      type = types.str;
      example = "192.168.1.50/24";
      default = machine.net.nic0.ip or "";
    };
  };

  config = lib.mkMerge [

    # Configure network manager
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (net.network-manager.enable) {
      networking.networkmanager = {
        enable = true;                      # Enable networkmanager and nm-applet
        dns = "systemd-resolved";           # Configure systemd-resolved as the DNS provider
        unmanaged = [                       # Ignore virtualization networks
          "interface-name:podman*"
        ];
      };

      # Enables ability for user to make network manager changes
      users.users.${machine.user.name}.extraGroups = [ "networkmanager" ];
    })

    # Configure basic networking
    # ----------------------------------------------------------------------------------------------
    {
      networking.enableIPv6 = false;
      networking.hostName = machine.hostname;
      networking.firewall.allowPing = true;
    }
    (lib.mkIf (machine.net.bridge.enable) {
      net.primary.name = machine.net.bridge.name;
    })

    # Configure DNS. resolved works well with network manager
    # DNS can be temporarily changed: sudo resolvectl dns enp1s0 1.1.1.1
    # ----------------------------------------------------------------------------------------------
    {
      services.resolved = {
        enable = true;
        dnssec = "allow-downgrade"; # using `dnssec = "true"` will break DNS if VPN DNS servers don't support
      };
    }
    (f.mkIfElse (machine.net.nic0.dns.primary != "" && machine.net.nic0.dns.fallback != "") {
      networking.nameservers = [ "${machine.net.nic0.dns.primary}" ];
      services.resolved.fallbackDns = [ "${machine.net.nic0.dns.fallback}" ];
    } (lib.mkIf (machine.net.nic0.dns.primary != "") {
      networking.nameservers = [ "${machine.net.nic0.dns.primary}" ];
    }))

    # Configure network bridge
    # ----------------------------------------------------------------------------------------------
    (f.mkIfElse (machine.net.bridge.enable) (lib.mkMerge [
      {
        assertions = [
          { assertion = (machine.net.bridge.name != ""); message = "Bridge name must be specified for bridge mode"; }
          { assertion = (machine.net.nic0.name != ""); message = "Primary nic must be specified e.g. 'eth0'"; } 
        ];
        networking.useDHCP = false;
        networking.bridges."${machine.net.bridge.name}".interfaces = ["${machine.net.nic0.name}" ];
      }

      # Configure static IP or DHCP for the bridge
      (f.mkIfElse (machine.net.nic0.ip != "") {
        assertions = [
          { assertion = (machine.net.nic0.subnet != ""); message = "NIC subnet was not specified"; } 
          { assertion = (machine.net.nic0.gateway != ""); message = "NIC gateway was not specified"; } 
        ];
        networking.interfaces."${machine.net.bridge.name}".ipv4.addresses = [ (f.toIP machine.net.nic0.ip) ];
        networking.defaultGateway = "${machine.net.nic0.gateway}";
      } {
        networking.interfaces."${machine.net.bridge.name}".useDHCP = true;
      })

      # Create host macvlan to communicate with containers on bridge otherwise the containers can be 
      # interacted with by every device on the LAN except the host due to local virtual oddities
      {
        networking.macvlans."${machine.net.macvlan.name}" = {
          interface = "${machine.net.bridge.name}";
          mode = "bridge";
        };
      }
      (f.mkIfElse (machine.net.macvlan.ip == "") {
        networking.interfaces."${machine.net.macvlan.name}".useDHCP = true;
      } {
        networking.interfaces."${machine.net.macvlan.name}".ipv4.addresses = [
          { address = "${machine.net.macvlan.ip}"; prefixLength = 32; }
        ];
      })

    # Otherwise configure primary NIC with static IP
    # ----------------------------------------------------------------------------------------------
    ]) (f.mkIfElse (machine.net.nic0.ip != "") {
      assertions = [
        { assertion = (machine.net.nic0.subnet != ""); message = "NIC subnet was not specified"; } 
        { assertion = (machine.net.nic0.gateway != ""); message = "NIC gateway was not specified"; } 
      ];

      networking.interfaces."${machine.net.nic0.name}".ipv4.addresses = [ (f.toIP machine.net.nic0.ip) ];
      networking.defaultGateway = "${machine.net.nic0.gateway}";
    } {
      # Finally fallback on DHCP for the primary NIC
    }))
  ];
}
