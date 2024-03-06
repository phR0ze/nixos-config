# Network Manager configuration
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  networking = {
   # useDHCP = false;
   # interfaces = { wlp0s20f3.useDHCP = true; };
    networkmanager = {
      enable = true;
      
      # Ignore virtualization technologies
      unmanaged = [
        "interface-name:docker*"
        "interface-name:vboxnet*"
        "interface-name:vmnet*"
    };
  };

  # Enables ability for user to make network manager changes
  users.users.${args.settings.username} = {
    extraGroups = [ "networkmanager" ];
  };
}
 
# vim:set ts=2:sw=2:sts=2
