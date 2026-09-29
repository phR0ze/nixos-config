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
#
# ### Other modules
# Other modules add groups to the admin user via `system.users.admin.extraGroups` and read its
# secret keys via `system.users.admin.*SecretRef`, rather than touching `secret.users."admin"`
# directly. Everything here only applies when `system.users.admin.enable` is set, so those
# settings are inert on hosts without an admin user e.g. the ISO.
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  cfg = config.system.users;
  passwordConfig = config.secret.files.${cfg.admin.passwordHashSecretRef}.path;
in
{
  options = {
    system.users = {
      admin = {
        enable = lib.mkEnableOption "Create admin user with secret name/pass from secrets.enc.yaml";
        passwordlessSudo = lib.mkEnableOption "Allow the admin user (wheel group) to sudo without a password";

        extraGroups = lib.mkOption {
          description = lib.mdDoc ''
            Additional groups for the admin user, on top of `wheel`. Set by other modules for the
            access they need e.g. `networkmanager`, `podman`, `kvm`.
          '';
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };

        userSecretRef = lib.mkOption {
          description = lib.mdDoc "Key in `sopsFile` holding the admin user's name";
          type = lib.types.str;
          default = "users/admin/name";
        };

        groupSecretRef = lib.mkOption {
          description = lib.mdDoc "Key in `sopsFile` holding the admin user's primary group name";
          type = lib.types.str;
          default = "users/admin/group";
        };

        passwordHashSecretRef = lib.mkOption {
          description = lib.mdDoc "Key in `sopsFile` holding the admin user's password hash (`mkpasswd -m sha-512`)";
          type = lib.types.str;
          default = "users/admin/passwordHash";
        };

        authorizedKeysSecretRef = lib.mkOption {
          description = lib.mdDoc "Key in `sopsFile` holding the admin user's SSH authorized keys";
          type = lib.types.str;
          default = "users/admin/authorizedKeys";
        };

        uid = lib.mkOption {
          description = lib.mdDoc "Admin user's uid";
          type = lib.types.int;
          default = 1000;
        };

        gid = lib.mkOption {
          description = lib.mdDoc "Admin user's primary group gid, pinned so file ownership stays stable";
          type = lib.types.int;
          default = 1000;
        };
      };

      desktopExtras = lib.mkEnableOption "Configure additional admin user settings for a desktop";

      sopsFile = lib.mkOption {
        description = lib.mdDoc ''
          Path to the host's `secrets.enc.yaml`, decrypted at activation time by sops-nix to
          source the admin user's name/group/password hash. Required when `system.users.admin`
          is enabled.
        '';
        type = lib.types.nullOr lib.types.path;
        default = null;
      };
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.desktopExtras -> cfg.admin.enable;
          message = "system.users.desktopExtras configures the admin user and requires system.users.admin.enable";
        }
      ];
    }

    (lib.mkIf (cfg.admin.enable) (lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.sopsFile != null;
            message = "system.users.admin is enabled but system.users.sopsFile is not set.";
          }
        ];

        secret.users.admin = {
          sopsFile = cfg.sopsFile;
          userSecretRef = cfg.admin.userSecretRef;
          groupSecretRef = cfg.admin.groupSecretRef;
          passwordHashSecretRef = cfg.admin.passwordHashSecretRef;
          authorizedKeysSecretRef = cfg.admin.authorizedKeysSecretRef;
          isNormalUser = true;
          uid = cfg.admin.uid;
          gid = cfg.admin.gid;
          extraGroups = [ "wheel" ] ++ cfg.admin.extraGroups;
        };

        # Make secret admin group runtime accessible by root
        secret.files.${cfg.admin.groupSecretRef} = { filemode = "0400"; sopsFile = cfg.sopsFile; };

        # Configure sudo access for system admin
        security.sudo.enable = true;
        security.sudo.wheelNeedsPassword = !cfg.admin.passwordlessSudo;
      }

      # Optionally configure additional desktop settings
      (lib.mkIf (cfg.desktopExtras) {
        secret.users.admin.extraGroups = [ "photos" "render" "users" "video" ];

        # Make secret admin password runtime accessible by root
        secret.files = {
          "users/admin/password" = { filemode = "0400"; sopsFile = cfg.sopsFile; };
          ${cfg.admin.passwordHashSecretRef} = { filemode = "0400"; sopsFile = cfg.sopsFile; };
        };

        # Set the root password to the same as the admin user
        # Overriding the ISO settings to avoid the duplicate values warning
        users.users.root.hashedPasswordFile = passwordConfig;

        # Create user groups for sharing files using specific ids
        users.groups."users".gid = 100;       # TODO: keep things runing as usual until I decomission this
        users.groups."photos".gid = 1100;     # named group for specific files access
      })
    ]))
  ];
}
