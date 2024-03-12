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
      ];
    };
  };

  # Set custom IP address
  #environment.etc."NetworkManager/system-connections/my-network.nmconnection" = {
  #  mode = "0600";
  #  source = ./files/my-network.nmconnection;
  #};

  # Enables ability for user to make network manager changes
  users.users.${args.settings.username} = {
    extraGroups = [ "networkmanager" ];
  };
}
