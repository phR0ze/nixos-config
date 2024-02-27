# Network Manager configuration
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  networking = {
    networkmanager.enable = true;             # easiest way to get networking up and runnning
  };
}

# vim:set ts=2:sw=2:sts=2
