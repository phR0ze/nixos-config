# Network Manager configuration
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  networking = {
    networkmanager.enable = true;
  };

  # Enables ability for user to make network manager changes
  users.users.${args.settings.username} = {
    extraGroups = [ "networkmanager" ];
  };
}
 
# vim:set ts=2:sw=2:sts=2
