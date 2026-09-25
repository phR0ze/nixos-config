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
# The permanent password below is `rdutil encrypt <plaintext-pass> --key <host.id>`'s output --
# a deterministic, already-encoded value, not the plaintext password itself -- so once
# `apps.network.rustdesk.secrets` is set, there's no need to run `rdutil` at activation/runtime the
# way the plaintext-password consumers (x11vnc/kasmvnc/adguardhome) do: just run `rdutil encrypt`
# once by hand when authoring `secrets.enc.yaml` and store its output under a `rustdesk/encodedPass`
# key, then it's rendered like any other sops-nix template placeholder. Machines without
# `apps.network.rustdesk.secrets` fall back to the old eval-time bake (`rdutil encrypt` run as a Nix
# derivation, leaking the plaintext password into the Nix store's builder script).
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.network.rustdesk;

  rustDeskTomlContent = (lib.concatStringsSep "\n"
    ([] ++ lib.optionals (cfg.allowDirectIPAccess)
      [ "password = '${if hasSecrets then config.secret.ref."rustdesk/encodedPass" else encoded-pass}'" ]
    )) + "\n";

  rustDeskTomlTemplates = lib.mapAttrs' (name: owner: {
    name = "rustdesk-permanent-pass-${name}";
    value = {
      path = "${owner.home}/.config/rustdesk/RustDesk.toml";
      inherit (owner) user group;
      content = rustDeskTomlContent;
      secrets = lib.optionalAttrs hasSecrets { "rustdesk/encodedPass".sopsFile = cfg.secrets; };
    };
  }) rustDeskOwners;
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

      secrets = lib.mkOption {
        type = types.nullOr types.path;
        default =
          let path = ../../../../hosts + "/${host.hostname}/secrets.enc.yaml";
          in if builtins.pathExists path then path else null;
        example = "./secrets.enc.yaml";
        description = lib.mdDoc ''
          Path to the sops-encrypted file holding this host's `rustdesk/encodedPass` secret
          (`rdutil encrypt <plaintext-pass> --key <host.id>`'s output). Independent of
          `host.secrets` because encodedPass is tied to this specific host's id and can't be
          satisfied by a shared/default secrets file. Defaults to
          `hosts/<hostname>/secrets.enc.yaml` if that file exists (relying on `host.hostname`
          always matching the `hosts/` directory name, set authoritatively by `flake.nix`);
          falls back to `null` (the legacy eval-time `rdutil` bake, which leaks the plaintext
          password into the Nix store) otherwise. Override only if a host's rustdesk secret
          genuinely lives elsewhere.
        '';
      };
    };
  };
 
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      environment.systemPackages = [
        pkgs.rdutil                   # custom tool for setting rustdesk password
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

      # Configure rustdesk permanent password encoded using the unique machine-id for this system
      files.all.".config/rustdesk/RustDesk.toml".text = (lib.concatStringsSep "\n"
        ([] ++ lib.optionals (cfg.allowDirectIPAccess)
          [ "password = '${encoded-pass}'" ]
        )) + "\n";
      #files.all.".config/rustdesk/RustDesk.toml" =
      #secret.templates = lib.mkIf hasSecrets rustDeskTomlTemplates;

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
    })

    # Configure RustDesk to autostart after login
    (lib.mkIf (cfg.enable && cfg.autostart) {
      environment.etc."xdg/autostart/rustdesk.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Terminal=false
        Exec=${pkgs.rustdesk-flutter}/bin/rustdesk --service
      '';
    })
  ];
}
