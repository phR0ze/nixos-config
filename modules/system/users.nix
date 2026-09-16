# User configuration
#
# ### Features
# - Configures default users and groups
#
# ### Secrets
# When `host.secrets` is set, the admin/root password is sourced from a pre-hashed
# (`mkpasswd -m sha-512`) `users/admin/passwordHash` entry in that host's `secrets.enc.yaml`,
# decrypted only at activation to sops-nix's default path (config.secret.files."users/admin/passwordHash".path,
# normally /run/secrets/users/admin/passwordHash) — never baked into the Nix store the way `initialPassword`
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  host = config.host;
  cfg = config.system.users;
  passwordConfig = config.secret.files."users/admin/passwordHash".path;
in
{ 
  options = {
    system.users = {
      admin.enable = lib.mkEnableOption "Create admin user with secret name/pass from secrets.enc.yaml";
      desktopExtras = lib.mkEnableOption "Configure additional settings for a desktop";
    };
  };

  config = lib.mkMerge [

    # Admin user with secret username and password
    (lib.mkIf (cfg.admin.enable) {
      secret.users."admin" = {
        sopsFile = host.secrets;
        userSecretRef = "users/admin/name";
        groupSecretRef = "users/admin/group";
        passwordHashSecretRef = "users/admin/passwordHash";
        isNormalUser = true;
        uid = 1000;
        extraGroups = [ "wheel" ];
      };

      # Configure sudo access for system admin
      security.sudo.enable = true;
    })

    # Optionally configure additional desktop settings
    (lib.mkIf (cfg.desktopExtras) {
      secret.users."admin" = {
        extraGroups = [ "photos" "render" "users" "video" ];
      };

      # Configure runtime admin user secrets
      secret.files = {
        "users/admin/password" = { filemode = "0400"; sopsFile = host.secrets; };
        "users/admin/passwordHash" = { filemode = "0400"; sopsFile = host.secrets; };
      };

      # Set the root password to the same as the admin user
      # Overriding the ISO settings to avoid the duplicate values warning
      users.users.root = passwordConfig;

      # Create user groups for sharing files using specific ids
      users.groups."users".gid = 100;       # TODO: keep things runing as usual until I decomission this
      users.groups."photos".gid = 1100;     # named group for specific files access

      # Configure passwordless sudo access for 'wheel' group
      security.sudo.wheelNeedsPassword = false;
    })
  ];
}
