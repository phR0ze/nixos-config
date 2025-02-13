# Import all the options
#
# ## Bridge vs Macvlan vs Macvtap
# There are a number of virtualized networking options that allow for connecting containers and VMs.
# I've determined that using a Bridge for the host is the best solution to build from as it is widely 
# used and driven by the community and provides the easiest path for exposing containers and VMs on 
# the LAN with their respective IPs and MAC addresses. The containers and VMs are then connected to 
# the bridge using a variety of Macvlan and Macvtap options.
#
# Note: I prefer to use a local Macvlan then to porford the container to that Macvlan as this will 
# provide an LAN IP address that is listable with `ip a` while eliminating any other access to/from 
# the container to the LAN. Alternatively if the container/VM is NixOS based then we cna use the 
# internal firewall to limit access.
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.machine;
  networking = config.networking;

  # Extract the primary nic if it exists
  filtered = builtins.filter (x: x.name == "primary") cfg.nics;
  nic0 = if (builtins.length filtered > 0) then builtins.elemAt filtered 0 else {};
in
{
  options = {
    networking.network-manager = {
      enable = lib.mkEnableOption "Install and configure network manager";
    };
    networking.primary.id = lib.mkOption {
      description = lib.mdDoc ''
        Primary interface to use for network access. This will typically just be the physical nic 
        e.g. ens18, but when 'machine.net.bridge.enable = true' it will be set to 
        'machine.net.bridge.name' e.g. br0 as the bridge will be the primary interface.
      '';
      type = types.str;
      default = if (!nic0 ? "id" || nic0.id == "") then "" else nic0.id;
    };
    networking.primary.ip = lib.mkOption {
      description = lib.mdDoc "Primary interface IP in CIDR notation";
      type = types.str;
      example = "192.168.1.50/24";
      default = if (!nic0 ? "ip" || nic0.ip == "") then "" else nic0.ip;
    };
  };

  config = lib.mkMerge [

    # Configure network manager
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (networking.network-manager.enable) {
      networking.networkmanager = {
        enable = true;                      # Enable networkmanager and nm-applet
        dns = "systemd-resolved";           # Configure systemd-resolved as the DNS provider
        unmanaged = [                       # Ignore virtualization networks
          "interface-name:podman*"
        ];
      };

      # Enables ability for user to make network manager changes
      users.users.${config.machine.user.name}.extraGroups = [ "networkmanager" ];
    })

    # Configure basic networking
    # ----------------------------------------------------------------------------------------------
    {
      networking.enableIPv6 = false;
      networking.hostName = cfg.hostname;
      networking.firewall.allowPing = true;
    }
    (lib.mkIf (cfg.net.bridge.enable) {
      networking.primary.id = cfg.net.bridge.name;
    })

    # Configure DNS. resolved works well with network manager
    # ----------------------------------------------------------------------------------------------
    {
      services.resolved = {
        enable = true;
        dnssec = "allow-downgrade"; # using `true` will break DNS if VPN DNS servers don't support
      };
    }
    (f.mkIfElse (cfg.net.dns.primary != "" && cfg.net.dns.fallback != "") {
      networking.nameservers = [ "${cfg.net.dns.primary}" ];
      services.resolved.fallbackDns = [ "${cfg.net.dns.fallback}" ];
    } (lib.mkIf (cfg.net.dns.primary != "") {
      networking.nameservers = [ "${cfg.net.dns.primary}" ];
    }))

    # Configure network bridge
    # ----------------------------------------------------------------------------------------------
    (f.mkIfElse (cfg.net.bridge.enable) (lib.mkMerge [
      {
        assertions = [
          { assertion = (cfg.net.bridge.name != ""); message = "Bridge name was not specified"; }
          { assertion = (cfg.net.macvlan.name != ""); message = "Macvlan name was not specified"; }
          { assertion = (nic0 ? "id" && nic0.id != ""); message = "NIC id was not specified"; } 
        ];
        networking.useDHCP = false;
        networking.bridges."${cfg.net.bridge.name}".interfaces = ["${nic0.id}" ];
      }

      # Configure static IP or DHCP for the bridge
      (f.mkIfElse (nic0.ip != "") {
        assertions = [
          { assertion = (nic0 ? "gateway" && nic0.gateway != ""); message = "NIC gateway was not specified"; } 
        ];
        networking.interfaces."${cfg.net.bridge.name}".ipv4.addresses = [ (f.toIP nic0.ip) ];
        networking.defaultGateway = "${nic0.gateway}";
      } {
        networking.interfaces."${cfg.net.bridge.name}".useDHCP = true;
      })

      # Create host macvlan to communicate with containers on bridge otherwise the containers can be 
      # interacted with by every device on the LAN except the host due to local virtual oddities
      {
        networking.macvlans."${cfg.net.macvlan.name}" = {
          interface = "${cfg.net.bridge.name}";
          mode = "bridge";
        };
      }
      (f.mkIfElse (cfg.net.macvlan.ip == "") {
        networking.interfaces."${cfg.net.macvlan.name}".useDHCP = true;
      } {
        networking.interfaces."${cfg.net.macvlan.name}".ipv4.addresses = [
          { address = "${cfg.net.macvlan.ip}"; prefixLength = 32; }
        ];
      })

    # Otherwise configure primary NIC with static IP/DHCP
    # ----------------------------------------------------------------------------------------------
    ]) (f.mkIfElse (nic0 ? "ip" && nic0.ip != "") {
      assertions = [
        { assertion = (nic0 ? "id"); message = "NIC id was not specified"; }
        { assertion = (nic0 ? "gateway"); message = "NIC gateway was not specified"; }
      ];

      networking.interfaces."${nic0.id}".ipv4.addresses = [ (f.toIP nic0.ip) ];
      networking.defaultGateway = "${nic0.gateway}";
    } {
      # Finally fallback on DHCP for the primary NIC
    }))
  ];
}
