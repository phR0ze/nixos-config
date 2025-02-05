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
{ config, lib, pkgs, f, ... }:
let
  cfg = config.networking;
  nic0 = config.machine.nic0;
  types = import ../types { inherit lib; };
in
{
  imports = [
    ./filezilla.nix
    ./firefox.nix
    ./qbittorrent.nix
    ./network-manager.nix
  ];

  # Networking bridge to allow host and containerized apps to interact and see each other on the LAN.
  # Although a Docker macvlan container will show up on the LAN and other devices on the LAN can
  # interact with it, an additional macvlan and specific routing is needed for the host to 
  # communicate with the container directly. This is true regardless of the use of a bridge actually 
  # but I really only need the container connection in the server case.
  options = {
    networking.bridge = {
      enable = lib.mkEnableOption "Convert the main interface into a bridge";
      name = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc "Bridge name to use";
        default = "br0";
      };
      macvlan = lib.mkOption {
        description = lib.mdDoc "Host macvlan interface";
        type = lib.types.submodule types.macvlan;
        example = {
          name = "host";
          ip = "192.168.1.49";
        };
        default = {
          name = "host";
          ip = "";
        };
      };
    };
    networking.vnic0 = lib.mkOption {
      type = lib.types.str;
      description = lib.mdDoc ''
        Primary interface to use for network access. This will typically just be the physical nic 
        e.g. ens18, but when networking.bridge is enabled it will be set to networking.bridge.name 
        to match the bridge.
      '';
      default = nic0.name;
    };
  };

  config = lib.mkMerge [

    # Configure basic networking
    # ----------------------------------------------------------------------------------------------
    {
      networking.enableIPv6 = false;
      networking.hostName = config.machine.hostname;
      networking.firewall = {
        allowPing = true;
      };
    }
    (lib.mkIf (cfg.bridge.enable) {
      networking.vnic0 = cfg.bridge.name;
    })

    # Configure DNS. resolved works well with network manager
    # ----------------------------------------------------------------------------------------------
    {
      services.resolved = {
        enable = true;
        dnssec = "allow-downgrade"; # using `true` will break DNS if VPN DNS servers don't support
      };
    }
    (f.mkIfElse (nic0.dns.primary != "" && nic0.dns.fallback != "") {
      networking.nameservers = [ "${nic0.dns.primary}" ];
      services.resolved.fallbackDns = [ "${nic0.dns.fallback}" ];
    } (lib.mkIf (nic0.dns.primary != "") {
      networking.nameservers = [ "${nic0.dns.primary}" ];
    }))

    # Configure network bridge
    # ----------------------------------------------------------------------------------------------
    (f.mkIfElse (cfg.bridge.enable) (lib.mkMerge [
      {
        assertions = [ { assertion = (nic0.name != ""); message = "NIC0 was not specified, please set 'nic0.name'"; } ];
        networking.useDHCP = false;
        networking.bridges."${cfg.bridge.name}".interfaces = [ "${nic0.name}" ];
      }

      # Configure static IP or DHCP for the bridge
      (f.mkIfElse (nic0.ip.full != "") {
        networking.interfaces."${cfg.bridge.name}".ipv4.addresses = [ nic0.ip.attrs ];
        networking.defaultGateway = "${nic0.gateway}";
      } {
        networking.interfaces."${cfg.bridge.name}".useDHCP = true;
      })

      # Create host macvlan to communicate with containers on bridge otherwise the containers can be 
      # interacted with by every device on the LAN except the host due to local virtual oddities
      {
        networking.macvlans."${cfg.bridge.macvlan.name}" = {
          interface = "${cfg.bridge.name}";
          mode = "bridge";
        };
      }
      (f.mkIfElse (cfg.bridge.macvlan.ip == "") {
        networking.interfaces."${cfg.bridge.macvlan.name}".useDHCP = true;
      } {
        networking.interfaces."${cfg.bridge.macvlan.name}".ipv4.addresses = [
          { address = "${cfg.bridge.macvlan.ip}"; prefixLength = 32; }
        ];
      })

    # Otherwise configure primary NIC with static IP/DHCP
    # ----------------------------------------------------------------------------------------------
    ]) (f.mkIfElse (nic0.ip.full != "") {
      networking.interfaces."${nic0.name}".ipv4.addresses = [ nic0.ip.attrs ];
      networking.defaultGateway = "${nic0.gateway}";
    } {
      # Finally fallback on DHCP for the primary NIC
    }))
  ];
}
