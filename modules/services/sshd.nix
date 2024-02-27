# SSHD configuration
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };
}

# vim:set ts=2:sw=2:sts=2
