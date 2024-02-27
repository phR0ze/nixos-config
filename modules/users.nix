# User configuration
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  # Set the root password to the same as the admin user
  users.extraUsers.root.password = args.settings.userpass;

  users.users.${args.settings.username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"                   # enables passwordless sudo for this user
      "networkmanager"          # enables ability for user to make network manager changes
    ];
    password = args.settings.userpass;  # temp password to change on first login
  };
}

# vim:set ts=2:sw=2:sts=2
