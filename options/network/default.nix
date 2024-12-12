# Import all the options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.networking;
  static_ip = f.toIP "${args.static_ip}";
  macvlanOpts = (import ../types/macvlan.nix { inherit lib; }).macvlanOpts;
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
        type = types.str;
        description = lib.mdDoc "Bridge name to use";
        default = "br0";
      };
      macvlan = lib.mkOption {
        description = lib.mdDoc "Host macvlan interface";
        type = types.submodule macvlanOpts;
        default = {
          name = "host";
          ip = "192.168.1.49";
        };
      };
    };
    networking.vnic0 = lib.mkOption {
      type = types.str;
      description = lib.mdDoc ''
        Primary interface to use for network access. This will typically just be the physical nic 
        e.g. ens18, but when networking.bridge is enabled it will be set to networking.bridge.name 
        to match the bridge.
      '';
      default = args.nic0;
    };
  };

  config = lib.mkMerge [

    # Configure basic networking
    # ----------------------------------------------------------------------------------------------
    {
      networking.enableIPv6 = false;
      networking.hostName = args.hostname;
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
    (lib.mkIf (args.primary_dns != "") {
      networking.nameservers = [ "${args.primary_dns}" ];
      services.resolved.fallbackDns = [ "${args.primary_dns}" ];
    })
    (lib.mkIf (args.primary_dns != "" && args.fallback_dns == "") {
      services.resolved.fallbackDns = [ "${args.primary_dns}" ];
    })
    (lib.mkIf (args.fallback_dns != "") {
      services.resolved.fallbackDns = [ "${args.fallback_dns}" ];
    })

    # Create host macvlan to communicate with containers on bridge otherwise the containers can be 
    # interacted with by every device on the LAN except the host due to local virtual oddities
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf cfg.bridge.enable {
      networking = {
        macvlans."${cfg.bridge.macvlan.name}" = {
          interface = "${cfg.bridge.name}";
          mode = "bridge";
        };
        interfaces."${cfg.bridge.macvlan.name}".ipv4.addresses = [
          { address = "${cfg.bridge.macvlan.ip}"; prefixLength = 32; }
        ];
      };
    })

    # Configure IP address for primary interface
    # ----------------------------------------------------------------------------------------------

    # Optionally configure network bridge with static IP
    (f.mkIfElse (cfg.bridge.enable && args.static_ip != "") {
      assertions = [
        { assertion = (args.nic0 != "");
          message = "NIC0 was not specified, please set 'args.nic0'"; }
      ];

      networking.useDHCP = false;
      networking.bridges."${cfg.bridge.name}".interfaces = [ "${args.nic0}" ];
      networking.interfaces."${cfg.bridge.name}".ipv4.addresses = [ static_ip ];
      networking.defaultGateway = "${args.gateway}";

    # Otherwise configure network bridge with DHCP second
    } (f.mkIfElse (cfg.bridge.enable && args.static_ip == "") {
      assertions = [
        { assertion = (args.nic0 != "");
          message = "NIC0 was not specified, please set 'args.nic0'"; }
      ];

      networking.useDHCP = false;
      networking.bridges."${cfg.bridge.name}".interfaces = [ "${args.nic0}" ];
      networking.interfaces."${cfg.bridge.name}".useDHCP = true;

    # Otherwise configure static IP for the primary NIC third
    } (f.mkIfElse (args.static_ip != "") {
      networking.interfaces."${args.nic0}".ipv4.addresses = [ static_ip ];
      networking.defaultGateway = "${args.gateway}";

    # Finally fallback on DHCP for the primary NIC
    } {
      # configure DHCP
    })))
  ];
}
