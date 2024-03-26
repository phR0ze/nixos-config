# User configuration
#
# ### Features
# - Configures users default groups
# - Configures users default passwords
#---------------------------------------------------------------------------------------------------
{ lib, pkgs, args, ... }:
{
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

  # Initialize user home
  # ------------------------------------------------------------------------------------------------
  files.any."foobar1".text = "this is a test"; 
  files.any."foobar2".link = ../include/home/.dircolors;
  files.any."foobar3".copy = ../include/home/.dircolors;
  files.root.".config".link = ../include/home/.config;
  files.root.".dircolors".copy = ../include/home/.dircolors;

#  security.pam.services.login.makeHomeDir = true;
#  users.extraUsers."me" = {
#    # Have to turn explicitly turn this off so PAM can do it on first login
#    createHome = false;
#  };
#  environment.home."foobar".text = ''
#    this is a test
#  ''; 
 # apps = [
 #   { foo = 1; bar = "one"; }
 # ];

  # Using writeTextFile functions to create files in nix store
  # https://nixos.org/manual/nixpkgs/unstable/#trivial-builder-text-writing
#  pkgs.writeTextFile {
#    name = "foobar";
#    text = ''
#      contents of the file
#    '';
  # Using 

#let
#  clamavUserScanner = pkgs.writeTextFile {
#    name = "clamav-user-scanner";
#    executable = true;
#    destination = "/bin/clamav-user-scanner.sh";
#    text = ''
#      # Script here...
#    '';
#in {
#  # ...
#  systemd.user.services.clamav-scan-weekly = {
#    description = "Perform a full scan of the user's home directory for viruses";
#    serviceConfig = {
#      Type = "oneshot";
#      ExecStart = "${clamavUserScanner}/bin/clamav-user-scanner.sh \"%h\"";
#    };
#  };
#  # ...
#}
}
