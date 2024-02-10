# User configuration
#---------------------------------------------------------------------------------------------------
{ systemSettings, ... }:
{
  # Set the root password to the same as the admin user
  users.users.root.initialPassword = systemSettings.userpass;

  users.users.${systemSettings.username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"                   # enables passwordless sudo for this user
      "networkmanager"          # enables ability for user to make network manager changes
    ];
    initialPassword = systemSettings.userpass;  # temp password to change on first login
  };
}

# vim:set ts=2:sw=2:sts=2
