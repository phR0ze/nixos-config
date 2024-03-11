# User configuration
#
# ### Features
# - Configures users default groups
# - Configures users default passwords
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  imports = [
    ./home.nix
  ];

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

#  # Initialize user home from /etc/skel on first login
#  # ------------------------------------------------------------------------------------------------
#  environment.etc = [
#    { source = ./software/config/vimrc; target = "skel/.vimrc"; }
#  ];
#  security.pam.services.login.makeHomeDir = true;
#  users.extraUsers."me" = {
#    # Have to turn explicitly turn this off so PAM can do it on first login
#    createHome = false;
#  };
#  environment.home."foobar".text = ''
#    this is a test
#  ''; 
  apps = [
    { foo = 1; bar = "one"; }
  ];
}
