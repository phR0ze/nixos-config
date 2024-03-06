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
    enableIPv6 = false;                    # disable IPv6
    hostName = args.settings.hostname;     # define hostname
    nameservers = [ "1.1.1.1" "1.0.0.1" ]; # use the Cloudflare DNS
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

# vim:set ts=2:sw=2:sts=2
