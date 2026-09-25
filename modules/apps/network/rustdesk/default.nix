# RustDesk configuration
#
# ### Description
# Open source project written in Rust providing both a client and server. The project is cross platform
# and available in AUR. Its meant to be a TeamViewer alternative and allows for remote service help
# like TeamViewer using an ID and RustDesk servers to connect in to assist your relatives or whatever.
# However you can also host the server and keep everything tightly controlled for a local solution as
# well.
#
# - Cross-platform support, MacOS, Windows, Linux and Android
# - Modern cross platform Flutter UI. Older Sciter based client is deprecated
# - Linux is X11 support only for now
#
# ### Configuration
# - Machine ID encrypted password is stored at ~/.config/rustdesk/RustDesk.toml
# - General configuration options are stored at ~/.config/rustdesk/RustDesk2.toml
# - RustDesk autostarts after login
#
# ### Other notes
# - [Advanced settings](https://rustdesk.com/docs/en/self-host/client-configuration/advanced-settings/)
#   - Direct IP access port is 21118
# - RustDesk supports encoding settings into the filename
#   - https://github.com/v0tti/rustdesk-configstring
#
# ### Secrets
# `rustdesk/encodedPass` is `rdutil encrypt <plaintext-pass> --key <host.id>`'s output, not the
# plaintext password. RustDesk 1.4.5 (`libs/hbb_common/src/password_security.rs`) encrypts the
# permanent password with libsodium `secretbox` using `get_uuid()` -- the machine id, i.e.
# `/etc/machine-id` on Linux -- zero-padded/truncated to 32 bytes as the key and an all-zero nonce,
# base64 (Original alphabet) encoded and prefixed with the version tag `00`. That's a deterministic
# function of `host.id`, which this repo pins per host, so the value can be computed once by hand
# when authoring `secrets.enc.yaml` and then rendered like any other sops-nix template placeholder
# -- no `rdutil` run at eval or activation time, and no plaintext password in the Nix store.
#
# `salt` is deliberately not pre-computed: RustDesk generates it on demand as a plain (unencrypted)
# random 6 character string (`Config::get_salt`), so there's nothing to seed.
#
# RustDesk.toml goes through `secret.templates`' `homePath` fan-out rather than `files.all`, for two
# reasons: `files.*` content always comes from a Nix store path so it can't carry a sops secret at
# all, and the admin account is created imperatively by nix-weave's `secret.users` (its name is
# itself a secret), so it only shows up in the passwd database at activation time. `homePath`
# handles both -- and its content-stamped install means the `enc_id`/`key_pair` RustDesk writes
# back into the same file on first run (this host's RustDesk ID) survive an unrelated rebuild,
# while a rotated password still propagates.
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.network.rustdesk;
in
{
  options = {
    apps.network.rustdesk = {
      enable = lib.mkEnableOption "Configure rustdesk Flutter based client";

      autostart = lib.mkOption {
        description = lib.mdDoc "Autostart RustDesk";
        type = types.bool;
        default = true;
      };

      allowLinuxHeadless = lib.mkOption {
        description = lib.mdDoc "Allow linux headless mode";
        type = types.bool;
        default = true;
      };

      service = lib.mkOption {
        description = lib.mdDoc ''
          Install as systemd service and autostart
          WIP, doesn't seem to currently work :(
        '';
        type = types.bool;
        default = false;
      };

      accessMode = lib.mkOption {
        description = lib.mdDoc "Provide full access for remote session";
        type = types.enum [ "full" "view" ];
        default = "full";
      };

      acceptSessionViaPassword = lib.mkOption {
        description = lib.mdDoc ''
          Accept RustDesk sessions after entering the password without prompting the remote user to
          click accept. Note this can be used with the click option to allow for both options.
        '';
        type = types.bool;
        default = true;
      };

      acceptSessionViaClick = lib.mkOption {
        description = lib.mdDoc ''
          Prompt the remote user to click accept in order to connect to the session.
          Note this can be used with the password option to allow for both options.
        '';
        type = types.bool;
        default = false;
      };

      useTemporaryPassword = lib.mkOption {
        description = lib.mdDoc ''
          Automatically generate a temporary password that can be used for access.
          Note this can be used with the permanent password such that either will work.
        '';
        type = types.bool;
        default = false;
      };

      usePermanentPassword = lib.mkOption {
        description = lib.mdDoc ''
          Use a permanent password for access.
          Note this can be used with the temporary password such that either will work.
        '';
        type = types.bool;
        default = true;
      };

      allowRemoteConfigModification = lib.mkOption {
        description = lib.mdDoc "Allow control side to change controlled settings";
        type = types.bool;
        default = true;
      };

      allowDirectIPAccess = lib.mkOption {
        description = lib.mdDoc "Allow remote users to connect directly by IP address";
        type = types.bool;
        default = true;
      };

      allowOnlyDirectIPAccess = lib.mkOption {
        description = lib.mdDoc "Only accept direct IP connections";
        type = types.bool;
        default = true;
      };

      enableDarkTheme = lib.mkOption {
        description = lib.mdDoc "Enable dark theme mode";
        type = types.bool;
        default = true;
      };

      sopsFile = lib.mkOption {
        description = lib.mdDoc ''
          Path to the sops-encrypted file holding this host's `rustdesk/encodedPass` secret, i.e.
          `rdutil encrypt <plaintext-pass> --key <host.id>`'s output. Tied to this specific host's
          `host.id`, so it can't be satisfied by a shared secrets file - defaults to
          `config.host.sopsFile` (`hosts/<hostname>/secrets.enc.yaml`) and only needs overriding
          if a host's rustdesk secret genuinely lives elsewhere.
        '';
        type = types.nullOr types.path;
        example = "./secrets.enc.yaml";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.allowDirectIPAccess || cfg.sopsFile != null;
          message = ''
            apps.network.rustdesk is enabled but apps.network.rustdesk.sopsFile is null - the
            permanent password comes from that file's `rustdesk/encodedPass` key. Generate it with
            `rdutil encrypt <password> --key <host.id>`.
          '';
        }
      ];

      environment.systemPackages = [
        pkgs.rdutil                   # custom tool for generating the encoded rustdesk password
        pkgs.rustdesk-flutter         # new standard client
        pkgs.xf86-video-dummy         # support for linux headless
      ];

      # Open up ports for the client to receive direct peer connections only
      networking.firewall.allowedTCPPorts = [ 21118 ];
      networking.firewall.allowedUDPPorts = [ 21118 ];

      # Configure rustdesk local client settings
      files.all.".config/rustdesk/RustDesk_local.toml".copy = (lib.concatStringsSep "\n"
        ([] ++ lib.optionals (cfg.enableDarkTheme)
          [ "[options]" "theme = 'dark'"]
        )) + "\n";

      # Configure RustDesk general options
      #   - the absence of an verification-method means both are accepted
      #   - the absence of an approve-mode means both are accepted
      files.all.".config/rustdesk/RustDesk2.toml".copy = (lib.concatStringsSep "\n"
        ([] ++ lib.optionals (cfg.allowOnlyDirectIPAccess)
          [ "rendezvous_server = '0.0.0.1'" "" ] # intentionally including a newline here
        ++ lib.optionals (cfg.usePermanentPassword && !cfg.useTemporaryPassword)
          [ "[options]" "verification-method = 'use-permanent-password'" ]
        ++ lib.optionals (cfg.useTemporaryPassword && !cfg.usePermanentPassword)
          [ "verification-method = 'use-temporary-password'" ]
        ++ [ "access-mode = '${cfg.accessMode}'" ]
        ++ lib.optionals (cfg.service || cfg.allowLinuxHeadless)
          [ "allow-linux-headless = 'Y'" ]
        ++ lib.optionals (cfg.allowRemoteConfigModification)
          [ "allow-remote-config-modification = 'Y'" ]
        ++ lib.optionals (cfg.acceptSessionViaClick && !cfg.acceptSessionViaPassword)
          [ "approve-mode = 'click'" ]
        ++ lib.optionals (cfg.acceptSessionViaPassword && !cfg.acceptSessionViaClick)
          [ "approve-mode = 'password'" ]
        ++ lib.optionals (cfg.allowDirectIPAccess)
          [ "direct-server = 'Y'" ]
        ++ lib.optionals (cfg.allowOnlyDirectIPAccess) [
            "custom-rendezvous-server = '0.0.0.1'"
            "relay-server = '0.0.0.1'"
            "api-server = 'http://0.0.0.1'"
          ]
        )) + "\n";
    }

    # Configure the rustdesk permanent password, encoded with this machine's unique machine-id.
    (lib.mkIf cfg.allowDirectIPAccess {
      secret.templates."rustdesk-permanent-pass" = {
        homePath = ".config/rustdesk/RustDesk.toml";
        includeRoot = true;
        filemode = "0600";
        content = "password = '${config.secret.ref."rustdesk/encodedPass"}'\n";
        secrets."rustdesk/encodedPass".sopsFile = cfg.sopsFile;
      };
    })

    # Configure RustDesk to autostart after login
    (lib.mkIf cfg.autostart {
      environment.etc."xdg/autostart/rustdesk.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Terminal=false
        Exec=${pkgs.rustdesk-flutter}/bin/rustdesk --service
      '';
    })
  ]);
}
