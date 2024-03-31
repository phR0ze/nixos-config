# SSHD configuration
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = if (args.iso) then "yes" else "no";
  };
}
