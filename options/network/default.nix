# Import all the options
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
  # interact with it an additional macvlan for the host and specific routing is needed for the host
  # to communicate with the container directly. This is true regardless of the use of a bridge
  # actually but I really only need the container connection in the server case.
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
        default = {
          name = "host";
          ip = "192.168.1.49";
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
#    (lib.mkIf (cfg.bridge.enable) {
#      networking.vnic0 = cfg.bridge.name;
#    })

    # Configure DNS. resolved works well with network manager
    # ----------------------------------------------------------------------------------------------
    {
      services.resolved = {
        enable = true;
        dnssec = "allow-downgrade"; # using `true` will break DNS if VPN DNS servers don't support
      };
    }
    (lib.mkIf (nic0.dns.primary != "") {
      networking.nameservers = [ "${nic0.dns.primary}" ];
      services.resolved.fallbackDns = [ "${nic0.dns.primary}" ];
    })
    (lib.mkIf (nic0.dns.primary != "" && nic0.dns.fallback == "") {
      services.resolved.fallbackDns = [ "${nic0.dns.primary}" ];
    })
    (lib.mkIf (nic0.dns.fallback != "") {
      services.resolved.fallbackDns = [ "${nic0.dns.fallback}" ];
    })

    # Create host macvlan to communicate with containers on bridge otherwise the containers can be 
    # interacted with by every device on the LAN except the host due to local virtual oddities
    # ----------------------------------------------------------------------------------------------
#    (lib.mkIf cfg.bridge.enable {
#      networking = {
#        macvlans."${cfg.bridge.macvlan.name}" = {
#          interface = "${cfg.bridge.name}";
#          mode = "bridge";
#        };
#        interfaces."${cfg.bridge.macvlan.name}".ipv4.addresses = [
#          { address = "${cfg.bridge.macvlan.ip}"; prefixLength = 32; }
#        ];
#      };
#    })

    # Configure IP address for primary interface
    # ----------------------------------------------------------------------------------------------
    {
      networking.interfaces."${nic0.name}".ipv4.addresses = [ nic0.ip.attrs ];
      networking.defaultGateway = "${nic0.gateway}";
    }

    # Optionally configure network bridge with static IP
#    (f.mkIfElse (cfg.bridge.enable && nic0.ip.full != "") {
#      assertions = [
#        { assertion = (nic0.name != "");
#          message = "NIC0 was not specified, please set 'nic0.name'"; }
#      ];
#
#      networking.useDHCP = false;
#      networking.bridges."${cfg.bridge.name}".interfaces = [ "${nic0.name}" ];
#      networking.interfaces."${cfg.bridge.name}".ipv4.addresses = [ nic0.ip.attrs ];
#      networking.defaultGateway = "${nic0.gateway}";
#
#    # Otherwise configure network bridge with DHCP second
#    } (f.mkIfElse (cfg.bridge.enable && nic0.ip.full == "") {
#      assertions = [
#        { assertion = (nic0.name != "");
#          message = "NIC0 was not specified, please set 'nic0.name'"; }
#      ];
#
#      networking.useDHCP = false;
#      networking.bridges."${cfg.bridge.name}".interfaces = [ "${nic0.name}" ];
#      networking.interfaces."${cfg.bridge.name}".useDHCP = true;
#
#    # Otherwise configure static IP for the primary NIC third
#    } (f.mkIfElse (nic0.ip.full != "") {
#      networking.interfaces."${nic0.name}".ipv4.addresses = [ nic0.ip.attrs ];
#      networking.defaultGateway = "${nic0.gateway}";
#
#    # Finally fallback on DHCP for the primary NIC
#    } {
#      # configure DHCP
#    })))
  ];
}
