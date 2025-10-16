# Defaults for building the ISO
# --------------------------------------------------------------------------------------------------
{
	user.name = "nixos";                  # Default user name
  user.fullname = "nixos";              # Default user full name
	user.email = "nixos";                 # Default user email address
	user.pass = "nixos";                  # Default user password
	git.user = "nixos";                   # Default github account user name
	git.group = "nixos";                  # Default github account user name
  git.email = "nixos";                  # Default github account user email

  net.subnet = "";
  net.gateway = "";
  net.dns.primary = "1.1.1.1";          # Default primary DNS to use for machine e.g. `1.1.1.1`
  net.dns.fallback = "8.8.8.8";         # Default fallback DNS to use for machine e.g. `8.8.8.8`
  net.nic0.name = "";                   # NIC system identifier e.g. ens18, eth0
  net.nic0.ip = "";                     # IP address to use for this NIC else DHCP, e.g. 192.168.1.12/24
  net.nic0.gateway = "";                # Default gateway to use for machine e.g. `192.168.1.1`
  net.nic0.subnet = "";                 # Default subnet to use for machine e.g. `192.168.1.0/24`
  net.nic0.dns.primary = "1.1.1.1";     # Default primary DNS to use for machine e.g. `1.1.1.1`
  net.nic0.dns.fallback = "8.8.8.8";    # Default fallback DNS to use for machine e.g. `8.8.8.8`
}
