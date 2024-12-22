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

  # Configure the system admin user
  users.users.${machine.user.name} = {
    uid = 1000;                         # ensure NixOS doesn't choose a different id for my user
    isNormalUser = true;
    extraGroups = [
      "wheel"                           # enables passwordless sudo for this user
      "video"                           # enables ability for user to login to graphical environment
    ];

    # User password or none if ISO
    initialPassword = lib.mkForce machine.user.pass;
  };

  # Ensure the users group always has the correct id
  users.groups."users".gid = 100;

  # Configure sudo access for system admin
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;         # Configure passwordless sudo access for 'wheel' group
  };

  # Initialize user home
  # ------------------------------------------------------------------------------------------------
  files.all.".dircolors".copy = ../include/home/.dircolors;
}
