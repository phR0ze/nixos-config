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

  # Initialize user home from /etc/skel on first login
  # ------------------------------------------------------------------------------------------------

  # Disable
  files.all."root/foobar1" = { enable = false; text = "this is a test"; };

  # Text cases
  files.all."root/text/text.file" = {
    kind = "file";
    dirmode = "0700";
    filemode = "0600";
    user = "admin";
    group = "users";
    own = false;
    text = ../include/home/.dircolors;
  };
  files.all."root/text.link".text = ../include/home/.dircolors;

  # File cases
  files.all."root/.dircolors".file = ../include/home/.dircolors;
  files.all."root/files/file1" = {
    dirmode = "0700";
    filemode = "0600";
    user = "admin";
    group = "users";
    own = false;
    file = ../include/home/.dircolors;
  };

  files.all."root/link1".link = ../include/home/.dircolors;
  files.all."root/links/link1" = {
    dirmode = "0700";
    filemode = "0600";
    user = "admin";
    group = "users";
    own = false;
    link = ../include/home/.dircolors;
  };

  # Dir cases
  files.all."root/.config".dir = ../include/home/.config;

#  config.foo = mkMerge [
#    (mkIf atHome {
#      option1 = something1;
#      option2 = something2;
#    })
#    (mkIf !atHome {
#      option3 = somethin3;
#    })
#  ];

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
