# Default networking configuration
#
# ### Features
# - Disables IPv6
# - DHCP systemd-networkd networking
# - Configures CloudFlare DNS
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  networking = {
  # useHostResolvConf = false;
    # address = "192.168.1.2";
    # prefixLength = 24;
    # defaultGateway = "192.168.1.1";
    hostName = args.settings.hostname;     # define hostname
    nameservers = [ "1.1.1.1" "1.0.0.1" ]; # use the Cloudflare DNS
    enableIPv6 = false;                    # disable IPv6 globally

    # Firewall configuration
    firewall = {
      enable = false;
#      allowedTCPPorts = [ 80 443 ];
#      allowedUDPPortRanges = [ ];
#      allowedTCPPortRanges = [
#        { from = 4000; to = 4007; }
#        { from = 8000; to = 8010; }
#      ];
    };
  };

#  services.resolved = {
#    enable = true;
#    dnssec = "false";
#    llmnr = "false";
#  };

#  services.avahi = lib.mkIf (config.my.mdns && !config.boot.isContainer) {
#    enable = true;
#    nssmdns = true;
#  };
}
