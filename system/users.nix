# User configuration
#---------------------------------------------------------------------------------------------------
{ systemSettings, ... }:
{
  users.users.${systemSettings.username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"                   # enables passwordless sudo for this user
      "networkmanager"          # enables ability for user to make network manager changes
    ];
    initialPassword = "nixos";  # temp password to change on first login
  };
}

# vim:set ts=2:sw=2:sts=2
