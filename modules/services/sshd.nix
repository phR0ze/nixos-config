# SSHD configuration
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };
}
