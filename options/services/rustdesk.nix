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
# - [Advanced settings](https://rustdesk.com/docs/en/self-host/client-configuration/advanced-settings/)
#   - Direct IP access port is 21118
# RustDesk supports encoding settings into the filename
# - https://github.com/v0tti/rustdesk-configstring
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.services.rustdesk;
  machine = config.machine;

  # Generate a machine-id encoded password for RustDesk
  encoded-pass = builtins.readFile (pkgs.runCommandLocal "encoded-rustdesk-pass" {} ''
    ${pkgs.rdutil}/bin/rdutil encrypt ${machine.user.pass} --key ${machine.id} > $out
  '');
in
{
  options = {
    services.rustdesk = {
      enable = lib.mkEnableOption "Configure rustdesk Flutter based client";
      autostart = lib.mkOption {
        description = lib.mdDoc "Autostart RustDesk";
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

    services.rustdesk.server = {
      enable = lib.mkEnableOption "Install and configure rustdesk server";
      relayHost = lib.mkOption {
        description = lib.mdDoc "IP/DNS name to use for the relay host";
        type = types.str;
        example = "192.168.1.2";
        default = config.networking.primary.ip;
      };
    };
  };
 
  config = lib.mkMerge [

    # Configure RustDesk Flutter client
    (lib.mkIf cfg.enable {
      environment.systemPackages = [
        pkgs.rustdesk-flutter         # new standard client
        pkgs.xorg.xf86videodummy      # support for linux headless
      ];

      # Open up ports for the client to receive connections
      networking.firewall.allowedTCPPorts = [ 21118 ];

      # Configure rustdesk permanent password encoded using the unique machine-id for this system
      files.all.".config/rustdesk/RustDesk.toml".text = (lib.concatStringsSep "\n"
        ([] ++ lib.optionals (cfg.allowDirectIPAccess)
          [ "password = '${encoded-pass}'" ]
        )) + "\n";

      # Configure RustDesk general options
      #   - the absence of an verification-method means both are accepted
      #   - the absence of an approve-mode means both are accepted
      files.all.".config/rustdesk/RustDesk2.toml".text = (lib.concatStringsSep "\n"
        ([] ++ lib.optionals (cfg.allowOnlyDirectIPAccess)
          [ "rendezvous_server = '0.0.0.1'" "" ] # intentionally including a newline here
        ++ [ "[options]" "access-mode = '${cfg.accessMode}'" ]
        ++ lib.optionals (cfg.usePermanentPassword && !cfg.useTemporaryPassword)
          [ "verification-method = 'use-permanent-password'" ]
        ++ lib.optionals (cfg.useTemporaryPassword && !cfg.usePermanentPassword)
          [ "verification-method = 'use-temporary-password'" ]
        ++ lib.optionals (cfg.acceptSessionViaClick && !cfg.acceptSessionViaPassword)
          [ "approve-mode = 'click'" ]
        ++ lib.optionals (cfg.acceptSessionViaPassword && !cfg.acceptSessionViaClick)
          [ "approve-mode = 'password'" ]
        ++ lib.optionals (cfg.allowRemoteConfigModification)
          [ "allow-remote-config-modification = 'Y'" ]
        ++ lib.optionals (cfg.enableDarkTheme)
          [ "allow-darktheme = 'Y'" ]
        ++ lib.optionals (cfg.allowDirectIPAccess)
          [ "direct-server = 'Y'" ]
        ++ lib.optionals (cfg.service)
          [ "allow-linux-headless = 'Y'" ]
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
      systemd.services.rustdesk = lib.mkIf (cfg.service) {
        description = "RustDesk";
        enable = true;
        requires = [ "network.target" ];              # fails this service if no network
        after = [ "systemd-user-sessions.service" ];  # start after network.target and login ready
        wantedBy = [ "multi-user.target" ];           # ensure starts at boot
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.rustdesk-flutter}/bin/rustdesk --service";
          ExecStop = ''${pkgs.procps}/bin/pkill -f "rustdesk --"'';
          PIDFile = "/run/rustdesk.pid";
          KillMode = "mixed";
          TimeoutStopSec = 5;
          LimitNOFILE = 100000;
        };
      };
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
    (lib.mkIf (cfg.server.enable) {
      assertions = [
        { assertion = (cfg.relayHost != ""); message = "Requires 'services.rustdesk.relayHost' be set"; }
      ];

      services.rustdesk-server.enable = true;
      services.rustdesk-server.openFirewall = true;
      services.rustdesk-server.relay.enable = true;
      services.rustdesk-server.signal = {
        enable = true;
        relayHosts = [ 
          (if(builtins.length (lib.splitString "/" cfg.relayHost) > 1) then
             (f.toIP cfg.relayHost).address
           else
             cfg.relayHost
          )
          cfg.relayHost
        ];
      };
    })
  ];
}
