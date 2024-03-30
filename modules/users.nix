# User configuration
#
# ### Features
# - Configures users default groups
# - Configures users default passwords
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, ... }: with lib;
{
  # Set the root password to the same as the admin user
  # Not setting this for the ISO path as was getting some weird warning and don't need this anyway
  # as the default system users is an administrator with sudo access.
  users.users.root.password = mkIf (args.install) args.settings.userpass;

  # Configure the system admin user
  users.users.${args.settings.username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"                           # enables passwordless sudo for this user
      "networkmanager"                  # enables ability for user to make network manager changes
      "video"                           # enables ability for user to login to graphical environment
    ];
    password = mkIf (args.install) args.settings.userpass;  # temp password to change on first login
  };

  # Configure sudo access for system admin
  security.sudo = {
    enable = true;

    # Configure passwordless sudo access for 'wheel' group
    wheelNeedsPassword = false;

    # Keep the environment variables of the calling user
#    extraConfig = ''
#      Defaults env_keep += "http_proxy HTTP_PROXY"
#      Defaults env_keep += "https_proxy HTTPS_PROXY"
#      Defaults env_keep += "ftp_proxy FTP_PROXY"
#    '';
  };

  # Initialize user home
  # ------------------------------------------------------------------------------------------------
  files.any."root/.config".link = ../include/home/.config;
  files.all.".dircolors".copy = ../include/home/.dircolors;

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
