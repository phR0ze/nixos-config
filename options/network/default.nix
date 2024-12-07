# Import all the options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  static_ip = f.toIP "${args.static_ip}";
in
{
  imports = [
    ./filezilla.nix
    ./firefox.nix
    ./qbittorrent.nix
    ./network-manager.nix
  ];

  config = lib.mkMerge [

    # Configure basic networking
    # ----------------------------------------------------------------------------------------------
    {
      networking.enableIPv6 = false;
      networking.hostName = args.hostname;
    }

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
    # Note: renaming NICs should be done using naming convention the kernel doesn't use like `lan0`
    # or you run the risk of a new NIC colliding.
    # ----------------------------------------------------------------------------------------------
#    systemd.network.links."10-rename" = {
#      matchConfig.Driver = "ipheth";
#      linkConfig.Name = "iphone";
#      networkingConfig.DHCP = true;
#    };

    # Optionally configure network bridge with static IP first
    (f.mkIfElse (args.network_bridge && args.static_ip != "") {
      networking.useDHCP = false;
      networking.bridges."br0".interfaces = [ "${args.nic0}" ];

      # Configure Static IP bridge
      networking.interfaces."br0".ipv4.addresses = [ static_ip ];
      networking.defaultGateway = "${args.gateway}";

    # Otherwise configure network bridge with DHCP second
    } (f.mkIfElse (args.network_bridge && args.static_ip == "") {
      networking.useDHCP = false;
      networking.bridges."br0".interfaces = [ "${args.nic0}" ];
      networking.interfaces."br0".useDHCP = true;

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
