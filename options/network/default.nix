# Import all the options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  static_ip = f.toIP "${args.settings.static_ip}";
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
      networking.hostName = args.settings.hostname;
    }

    # Configure DNS. resolved works well with network manager
    # ----------------------------------------------------------------------------------------------
    {
      services.resolved = {
        enable = true;
        dnssec = "allow-downgrade"; # using `true` will break DNS if VPN DNS servers don't support
      };
    }
    (lib.mkIf (args.settings.primary_dns != "") {
      networking.nameservers = [ "${args.settings.primary_dns}" ];
      services.resolved.fallbackDns = [ "${args.settings.primary_dns}" ];
    })
    (lib.mkIf (args.settings.primary_dns != "" && args.settings.fallback_dns == "") {
      services.resolved.fallbackDns = [ "${args.settings.primary_dns}" ];
    })
    (lib.mkIf (args.settings.fallback_dns != "") {
      services.resolved.fallbackDns = [ "${args.settings.fallback_dns}" ];
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
    (f.mkIfElse (args.settings.network_bridge && args.settings.static_ip != "") {
      networking.useDHCP = false;
      networking.bridges."br0".interfaces = [ "${args.settings.nic1}" ];

      # Configure Static IP bridge
      networking.interfaces."br0".ipv4.addresses = [ static_ip ];
      networking.defaultGateway = "${args.settings.gateway}";

    # Otherwise configure network bridge with DHCP second
    } (f.mkIfElse (args.settings.network_bridge && args.settings.static_ip == "") {
      networking.useDHCP = false;
      networking.bridges."br0".interfaces = [ "${args.settings.nic1}" ];
      networking.interfaces."br0".useDHCP = true;

    # Otherwise configure static IP for the primary NIC third
    } (f.mkIfElse (args.settings.static_ip != "") {
      networking.interfaces."${args.settings.nic1}".ipv4.addresses = [ static_ip ];
      networking.defaultGateway = "${args.settings.gateway}";

    # Finally fallback on DHCP for the primary NIC
    } {
      # configure DHCP
    })))
  ];
}
