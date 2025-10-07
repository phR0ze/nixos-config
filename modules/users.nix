# User configuration
#
# ### Features
# - Configures users default groups
# - Configures users default passwords
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  machine = config.machine;
in
{
  # Set the root password to the same as the admin user
  # Overriding the ISO settings to avoid the duplicate values warning
  users.users.root.initialPassword = lib.mkForce machine.user.pass;

  # Configure the default system admin user
  users.users.${machine.user.name} = {
    uid = 1000;                         # ensure NixOS doesn't choose a different id for my user
    isNormalUser = true;
    group = "users";                    # create the users group for the system admin user
    extraGroups = [
      "photos"                          # provides a sharable group to work with photos
      "render"                          # enables transcoding hardware acceleration support
      "users"                           # provides a sharable group for generic user files
      "video"                           # enables ability for user to login to graphical environment
      "wheel"                           # enables passwordless sudo for this user
    ];

    # User password or none if ISO
    initialPassword = lib.mkForce machine.user.pass;
  };

  # Create user groups for sharing files using specific ids
  users.groups."photos".gid = 1100;     # named group for specific files access
  users.groups."users".gid = 100;       # TODO: keep things runing as usual until I decomission this

  # Ensure private user group that always has the correct id
  users.groups."${machine.user.name}".gid = 1000;

  # Configure sudo access for system admin
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;         # Configure passwordless sudo access for 'wheel' group
  };
}
