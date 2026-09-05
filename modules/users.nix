# User configuration
#
# ### Features
# - Configures users default groups
# - Configures users default passwords
#
# ### Secrets
# When `host.secrets` is set, the admin/root password is sourced from a pre-hashed
# (`mkpasswd -m sha-512`) `user/passwordHash` entry in that host's `secrets.enc.yaml`,
# decrypted only at activation to `/run/files/user-passwordhash` — never baked into the Nix store the
# way `initialPassword` does. Machines that haven't been migrated to a `secrets.enc.yaml` yet
# (`host.secrets == null`) fall back to the old `initialPassword` behavior so this can land
# ahead of the per-host secrets rollout.
#
# Also declares the *plaintext* `user/password` secret (decrypted to /run/files/user-password)
# here, once, for the handful of modules (rustdesk, x11vnc, kasmvnc, adguardhome) that need the
# plaintext value at runtime to run their own password-hashing tool (`rdutil encrypt`, `x11vnc -storepasswd`,
# `vncpasswd`, `htpasswd`) rather than a pre-hashed value like `hashedPasswordFile` wants -- they
# reference the literal /run/files/user-password path directly instead of redeclaring this secret
# themselves. (nixos-files' `files.any.<target>.encrypted` names the generated `sops.secrets`
# entry after `<target>` itself, not `encrypted.key`, so the install path is always the same
# literal string as the `files.any` key -- referencing it directly avoids the mismatch.)
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  host = config.host;
  hasSecrets = host.secrets != null;

  passwordConfig = if hasSecrets
    then { hashedPasswordFile = lib.mkForce "/run/files/user-passwordhash"; }
    else { initialPassword = lib.mkForce host.user.pass; };
in
{
  config = lib.mkMerge [
    (lib.mkIf hasSecrets {
      files.any = {
        "/run/files/user-passwordhash" = {
          filemode = "0400";
          encrypted = {
            sopsFile = host.secrets;
            key = "user/passwordHash";
          };
        };
        "/run/files/user-password" = {
          filemode = "0400";
          encrypted = {
            sopsFile = host.secrets;
            key = "user/password";
          };
        };
      };
    })

    {
      # Set the root password to the same as the admin user
      # Overriding the ISO settings to avoid the duplicate values warning
      users.users.root = passwordConfig;

      # Configure the default system admin user
      users.users.${host.user.name} = {
        uid = 1000;                         # ensure NixOS doesn't choose a different id for my user
        isNormalUser = true;
        group = "${host.user.group}";     # create the users group for the system admin user
        extraGroups = [
          "photos"                          # provides a sharable group to work with photos
          "render"                          # enables transcoding hardware acceleration support
          "users"                           # provides a sharable group for generic user files
          "video"                           # enables ability for user to login to graphical environment
          "wheel"                           # enables passwordless sudo for this user
        ];
      } // passwordConfig;

      # Create user groups for sharing files using specific ids
      users.groups."photos".gid = 1100;     # named group for specific files access
      users.groups."users".gid = 100;       # TODO: keep things runing as usual until I decomission this

      # Ensure private user group that always has the correct id
      users.groups."${host.user.group}".gid = 1000;

      # Configure sudo access for system admin
      security.sudo = {
        enable = true;
        wheelNeedsPassword = false;         # Configure passwordless sudo access for 'wheel' group
      };
    }
  ];
}
