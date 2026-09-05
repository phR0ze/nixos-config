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
#
# `files.templates` has no per-user home-directory expansion the way `files.all` does (it only
# knows absolute paths), so RustDesk.toml's per-real-user `files.templates` entries are built by
# hand below, mirroring nixos-files' own `files.all` expansion (every `isNormalUser` account, plus
# a root copy at /root/.config/...).
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  host = config.host;
  cfg = config.apps.network.rustdesk;
  # Deliberately its own option rather than reading `host.secrets` directly: encodedPass is
  # `rdutil encrypt <pass> --key <host.id>`'s output, so it's cryptographically tied to this
  # specific host's id and can never be satisfied by a shared/default secrets file the way
  # `host.secrets` can for `user.password`/`passwordHash` in modules/users.nix.
  hasSecrets = cfg.secrets != null;

  # Legacy eval-time bake -- fallback until this host has an `apps.network.rustdesk.secrets` file
  encoded-pass = builtins.readFile (pkgs.runCommandLocal "encoded-rustdesk-pass" {} ''
    ${pkgs.rdutil}/bin/rdutil encrypt "${host.user.pass}" --key "${host.id}" > $out
  '');

  rustDeskTomlContent = (lib.concatStringsSep "\n"
    ([] ++ lib.optionals (cfg.allowDirectIPAccess)
      [ "password = '${if hasSecrets then config.sops.placeholder."rustdesk/encodedPass" else encoded-pass}'" ]
    )) + "\n";

  # root plus every real (isNormalUser) account, named -> { user; group; home; }
  rustDeskOwners = { root = { user = "root"; group = "root"; home = "/root"; }; } //
    (lib.mapAttrs (uname: u: { user = uname; group = u.group; home = u.home; })
      (lib.filterAttrs (_: u: u.isNormalUser) config.users.users));

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

      secrets = lib.mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "./secrets.enc.yaml";
        description = lib.mdDoc ''
          Path to the sops-encrypted file holding this host's `rustdesk/encodedPass` secret
          (`rdutil encrypt <plaintext-pass> --key <host.id>`'s output). Independent of
          `host.secrets` because encodedPass is tied to this specific host's id and can't be
          satisfied by a shared/default secrets file. Leave unset to fall back to the legacy
          eval-time `rdutil` bake (leaks the plaintext password into the Nix store).
        '';
      };

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
    };

#    apps.network.rustdesk.server = {
#      enable = lib.mkEnableOption "Install and configure rustdesk server";
#      relayHost = lib.mkOption {
#        description = lib.mdDoc "IP/DNS name to use for the relay host";
#        type = types.str;
#        example = "192.168.1.2";
#        default = host.net.nic0.ip;
#      };
#    };
  };
 
  config = lib.mkMerge [

    # Configure RustDesk Flutter client
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

      # Configure rustdesk permanent password encoded using the unique machine-id for this system.
      # `files.templates` has no per-user expansion, so this is built by hand above (rustDeskTomlTemplates).
      files.all.".config/rustdesk/RustDesk.toml" = lib.mkIf (!hasSecrets) { copy = rustDeskTomlContent; };
      files.templates = lib.mkIf hasSecrets rustDeskTomlTemplates;

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

      # Configure RustDesk to start with the system
      # WIP - wasn't able to get this to work correctly
      #
      # - https://github.com/rustdesk/rustdesk/blob/master/res/rustdesk.service
      # - https://github.com/rustdesk/rustdesk/wiki/Headless-Linux-Support
      # - sudo rustdesk --option allow-linux-headless Y
#      systemd.services.rustdesk = lib.mkIf (cfg.service) {
#        description = "RustDesk";
#        enable = true;
#        requires = [ "network.target" ];              # fails this service if no network
#        after = [ "systemd-user-sessions.service" ];  # start after network.target and login ready
#        wantedBy = [ "multi-user.target" ];           # ensure starts at boot
#        serviceConfig = {
#          Type = "simple";
#          ExecStart = "${pkgs.rustdesk-flutter}/bin/rustdesk --service";
#          ExecStop = ''${pkgs.procps}/bin/pkill -f "rustdesk --"'';
#          PIDFile = "/run/rustdesk.pid";
#          KillMode = "mixed";
#          TimeoutStopSec = 5;
#          LimitNOFILE = 100000;
#        };
#      };
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

    # Configure server
#    (lib.mkIf (cfg.server.enable) {
#      assertions = [
#        { assertion = (cfg.relayHost != ""); message = "Requires 'services.rustdesk.relayHost' be set"; }
#      ];
#
#      services.rustdesk-server.enable = true;
#      services.rustdesk-server.openFirewall = true;
#      services.rustdesk-server.relay.enable = true;
#      services.rustdesk-server.signal = {
#        enable = true;
#        relayHosts = [ 
#          (if(builtins.length (lib.splitString "/" cfg.relayHost) > 1) then
#             (f.toIP cfg.relayHost).address
#           else
#             cfg.relayHost
#          )
#          cfg.relayHost
#        ];
#      };
#    })
  ];
}
