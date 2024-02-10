# Networking configuration
#---------------------------------------------------------------------------------------------------
{ systemSettings, ... }:
{
  networking = {
    hostName = systemSettings.hostname;     # define hostname
    enableIPv6 = false;                     # disable IPv6
    nameservers = [ "1.1.1.1" "1.0.0.1" ];  # use the Cloudflare DNS
    networkmanager.enable = true;           # easiest way to get networking up and runnning
    # wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  };
}

# vim:set ts=2:sw=2:sts=2
