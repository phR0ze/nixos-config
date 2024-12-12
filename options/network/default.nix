# Import all the options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.networking;
  static_ip = f.toIP "${args.static_ip}";
in
{
  imports = [
    ./filezilla.nix
    ./firefox.nix
    ./qbittorrent.nix
    ./network-manager.nix
  ];

  options = {
    networking = {
      bridge = {
        enable = lib.mkEnableOption "Convert the main interface into a bridge";
        name = lib.mkOption {
          type = types.str;
          description = lib.mdDoc "Bridge name to use";
          default = "br0";
        };
      };
      vnic0 = lib.mkOption {
        type = types.str;
        description = lib.mdDoc ''
          Primary interface to use for network access. This will typically just be the physical nic 
          e.g. ens18, but when networking.bridge is enabled it will be set to networking.bridge.name 
          to match the bridge.
        '';
        default = args.nic0;
      };
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
