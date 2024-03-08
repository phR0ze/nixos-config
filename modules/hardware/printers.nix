# Printer configuration
#
# ### Details
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  services.printing = {
    enable = true;
    browsing = true;
    #drivers = [ pkgs.gutenprint pkgs.brlaser pkgs.mfcl2740dwlpr pkgs.mfcl2740dwcupswrapper ];
  };
  #services.avahi.enable = true;
  #services.avahi.nssmdns = true;
}
