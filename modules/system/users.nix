# User configuration
#
# ### Features
# - Configures users default groups
# - Configures users default passwords
#
# ### Secrets
# When `host.secrets` is set, the admin/root password is sourced from a pre-hashed
# (`mkpasswd -m sha-512`) `user/passwordHash` entry in that host's `secrets.enc.yaml`,
# decrypted only at activation to sops-nix's default path (config.secret.files."user-passwordhash".path,
# normally /run/secrets/user-passwordhash) — never baked into the Nix store the way `initialPassword`
#
# Also declares the *plaintext* `user/password` secret (as secret.files."user-password", decrypted
# to config.secret.files."user-password".path) below, for the handful of modules (rustdesk, x11vnc,
# kasmvnc, adguardhome) that need the plaintext value at runtime to run their own password-hashing
# tool (`rdutil encrypt`, `x11vnc -storepasswd`, `vncpasswd`, `htpasswd`) rather than a pre-hashed
# value like `hashedPasswordFile` wants -- they reference config.secret.files."user-password".path
# directly instead of redeclaring this secret themselves. A bare (no leading "/") secret.files
# identifier is used deliberately here so the decrypted path is left at sops-nix's own default
# rather than hardcoded to an arbitrary location.
#
# When `host.user.secret` is also set, the admin account itself is created via nix-weave's
# `secret.users` instead of the declarative `users.users.${host.user.name}` below -- see that
# option's description in modules/types/user.nix for why (username can't be a Nix attribute name
# and a runtime-only secret at the same time).
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  host = config.host;
  hasSecrets = host.secrets != null;

  passwordConfig = if hasSecrets
    then { hashedPasswordFile = lib.mkForce config.secret.files."user-passwordhash".path; }
    else { initialPassword = lib.mkForce host.user.pass; };
in
{
  config = lib.mkMerge [
    (lib.mkIf hasSecrets {
      secret.files."user-passwordhash" = {
        filemode = "0400";
        sopsFile = host.secrets;
        key = "user/passwordHash";
      };
    })

    # The plaintext password is only needed at runtime by modules (rustdesk, x11vnc, kasmvnc,
    # adguardhome) that hash it themselves with their own tool - host.user.secret hosts create
    # their admin account via passwordHashSecretRef instead (see below), so they never need the
    # plaintext decrypted to disk at all.
    (lib.mkIf (hasSecrets && !host.user.secret) {
      secret.files."user-password" = {
        filemode = "0400";
        sopsFile = host.secrets;
        key = "user/password";
      };
    })

    {
      # Set the root password to the same as the admin user
      # Overriding the ISO settings to avoid the duplicate values warning
      users.users.root = passwordConfig;

      # Create user groups for sharing files using specific ids
      users.groups."photos".gid = 1100;     # named group for specific files access
      users.groups."users".gid = 100;       # TODO: keep things runing as usual until I decomission this

      # Configure sudo access for system admin
      security.sudo = {
        enable = true;
        wheelNeedsPassword = false;         # Configure passwordless sudo access for 'wheel' group
      };
    }

    (lib.mkIf (!host.user.secret) {
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

      # Ensure private user group that always has the correct id
      users.groups."${host.user.group}".gid = 1000;
    })

    # Same account as above, but the username/group/password are only known once sops-nix decrypts
    # them at activation - see host.user.secret's description for why. Uses passwordHashSecretRef
    # rather than passwordSecretRef so the plaintext password is never decrypted to disk at all,
    # even transiently - only the pre-hashed user/passwordHash value (already needed for root
    # above) is used.
    (lib.mkIf host.user.secret {
      secret.users."admin" = {
        sopsFile = host.secrets;
        userSecretRef = "user/name";
        groupSecretRef = "user/group";
        passwordHashSecretRef = "user/passwordHash";
        isNormalUser = true;
        uid = 1000;
        extraGroups = [ "photos" "render" "users" "video" "wheel" ];
      };
    })
  ];
}
