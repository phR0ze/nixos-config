# Base networking configuration
#
# ### Features
# - Disables IPv6
# - DHCP systemd-networkd networking
# - Configures CloudFlare DNS
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  networking = {
    enableIPv6 = false;                       # disable IPv6
    hostName = args.systemSettings.hostname;  # define hostname
    nameservers = [ "1.1.1.1" "1.0.0.1" ];    # use the Cloudflare DNS
  };
}

# vim:set ts=2:sw=2:sts=2
