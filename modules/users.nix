# User configuration
#
# ### Features
# - Configures users default groups
# - Configures users default passwords
#---------------------------------------------------------------------------------------------------
{ lib, args, ... }:
{
  # Set the root password to the same as the admin user
  # Overriding the ISO settings to avoid the duplicate values warning
  users.users.root.initialPassword = lib.mkForce args.settings.userpass;

  # Configure the system admin user
  users.users.${args.settings.username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"                           # enables passwordless sudo for this user
      "video"                           # enables ability for user to login to graphical environment
    ];

    # User password or none if ISO
    initialPassword = lib.mkForce args.settings.userpass;
  };

  # Configure sudo access for system admin
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;         # Configure passwordless sudo access for 'wheel' group
  };

  # Initialize user home
  # ------------------------------------------------------------------------------------------------
  files.all.".dircolors".copy = ../include/home/.dircolors;
}
