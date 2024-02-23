# Base networking configuration
#
# ### Features
# - DHCP systemd-networkd networking
# - Disables IPv6
# - Configures CloudFlare DNS
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  networking = {
    hostName = args.systemSettings.hostname;  # define hostname
    enableIPv6 = false;                       # disable IPv6
    nameservers = [ "1.1.1.1" "1.0.0.1" ];    # use the Cloudflare DNS
  };
}

# vim:set ts=2:sw=2:sts=2
