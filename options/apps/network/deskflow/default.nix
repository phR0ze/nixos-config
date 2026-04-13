# Deskflow options
#
# Deskflow is KVM software (successor to Barrier/Synergy) that allows a single keyboard
# and mouse to control multiple computers. This module provides both server and client
# configurations using the nixpkgs deskflow package.
#
# ### Usage
#   Server: apps.network.deskflow.server.enable = true;
#   Client: apps.network.deskflow.client = { enable = true; server = "192.168.1.10"; };
#
# ### macOS client
#   Install via Homebrew: brew install deskflow/tap/deskflow
#   TLS is on by default; if disabling on the server, disable it in the macOS GUI as well.
#
# ### References
# - https://github.com/deskflow/deskflow
# - https://deskflow.org
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;

let
  cfgC = config.apps.network.deskflow.client;
  cfgS = config.apps.network.deskflow.server;

  deskflowConfig = lib.mkIf cfgS.enable
    (pkgs.writeText "deskflow.conf" ''
      section: screens
        ${cfgS.name}:
        ${cfgS.clientName}:
      end
      section: links
        ${cfgS.name}:
          right = ${cfgS.clientName}
        ${cfgS.clientName}:
          left = ${cfgS.name}
      end
    '');
in
{
  options = {
    apps.network.deskflow.server = {
      enable = lib.mkEnableOption "Deskflow server (KVM)";

      configFile = lib.mkOption {
        type = types.path;
        default = "/etc/deskflow.conf";
        description = "Deskflow server screen layout configuration file.";
      };

      name = lib.mkOption {
        type = types.str;
        default = "server";
        description = "Use this name for the server in the screen configuration.";
      };

      clientName = lib.mkOption {
        type = types.str;
        default = "client";
        description = "Use this name for the client in the screen configuration.";
      };

      address = lib.mkOption {
        type = types.str;
        default = "";
        description = "Address on which to listen for clients (e.g. 192.168.1.10:24800).";
      };

      autoStart = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Whether the Deskflow server should be started automatically.";
      };

      enableTls = lib.mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable TLS encryption. When false, passes --disable-crypto.
          Note: if enabling TLS, the macOS client must also have TLS enabled and
          fingerprints accepted via the Deskflow GUI before headless operation.
        '';
      };
    };

    apps.network.deskflow.client = {
      enable = lib.mkEnableOption "Deskflow client (KVM)";

      name = lib.mkOption {
        type = types.str;
        default = "client";
        description = "Make this name match what is expected in the screen configuration on the server.";
      };

      server = lib.mkOption {
        type = types.str;
        default = "";
        description = ''
          The server address of the form [hostname][:port]. The port overrides the
          default port, 24800.
        '';
      };

      autoStart = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Whether the Deskflow client should be started automatically.";
      };

      enableTls = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Enable TLS encryption. Must match the server's TLS setting.";
      };
    };
  };

  config = lib.mkMerge [

    # Install deskflow when either component is enabled
    (lib.mkIf (cfgC.enable || cfgS.enable) {
      environment.systemPackages = [ pkgs.deskflow ];
    })

    # Server configuration
    (lib.mkIf cfgS.enable {

      # Must allow clients to connect through the firewall
      # View rules with: sudo iptables -S
      networking.firewall.allowedTCPPorts = [ 24800 ];

      # Lay down the screen layout configuration
      environment.etc."deskflow.conf".source = deskflowConfig;

      systemd.user.services.deskflow-server = {
        description = "Deskflow server";
        after = [ "network.target" "graphical-session.target" ];
        wantedBy = lib.optional cfgS.autoStart "graphical-session.target";
        path = [ pkgs.deskflow ];
        serviceConfig.Restart = "on-failure";
        serviceConfig.ExecStart = toString (
          [ "${pkgs.deskflow}/bin/deskflow-core" "server" ]
          ++ [ "-c" cfgS.configFile ]
          ++ lib.optional (cfgS.address != "") [ "--address" cfgS.address ]
          ++ lib.optional (cfgS.name != "") [ "--name" cfgS.name ]
          ++ lib.optional (!cfgS.enableTls) "--disable-crypto"
        );
      };
    })

    # Client configuration
    (lib.mkIf cfgC.enable {
      systemd.user.services.deskflow-client = {
        description = "Deskflow client";
        after = [ "network.target" "graphical-session.target" ];
        wantedBy = lib.optional cfgC.autoStart "graphical-session.target";
        path = [ pkgs.deskflow ];
        serviceConfig.Restart = "on-failure";
        serviceConfig.ExecStart = toString (
          [ "${pkgs.deskflow}/bin/deskflow-core" "client" ]
          ++ lib.optional (cfgC.name != "") [ "--name" cfgC.name ]
          ++ lib.optional (!cfgC.enableTls) "--disable-crypto"
          ++ lib.optional (cfgC.server != "") cfgC.server
        );
      };
    })
  ];
}
