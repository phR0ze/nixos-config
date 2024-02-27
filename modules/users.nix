# User configuration
#
# ### Features
# - Activate Home Manager for use in other modules
# - Configure default users
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  imports = [
    args.home-manager.nixosModules.home-manager
  ];

  # Configure Home Manager
  # ------------------------------------------------------------------------------------------------
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = false;

    # Define root user

    # Define system user
    users.${args.settings.username} = {
      home = {
        username = "${args.settings.username}";
        homeDirectory = "/home/${args.settings.username}";
        stateVersion = args.settings.stateVersion;
      };
    };
  };

  # Configure general user settings
  # ------------------------------------------------------------------------------------------------

  # Set the root password to the same as the admin user
  users.extraUsers.root.password = args.settings.userpass;

  users.users.${args.settings.username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"                           # enables passwordless sudo for this user
      "networkmanager"                  # enables ability for user to make network manager changes
    ];
    password = args.settings.userpass;  # temp password to change on first login
  };
}

# vim:set ts=2:sw=2:sts=2
