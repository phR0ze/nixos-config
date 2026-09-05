# Deskflow options
#
# Deskflow is KVM software (successor to Barrier/Synergy) that allows a single keyboard
# and mouse to control multiple computers. This module provides both server and client
# configurations using the nixpkgs deskflow package.
#
# deskflow-core accepts only a single -s <settingsFile> flag. All configuration
# (screen name, TLS, interface, server layout path) lives in an INI-format settings
# file. This module generates both the settings file and the screen layout config.
#
# ### Usage
#   Server: apps.network.deskflow.server.enable = true;
#   Client: apps.network.deskflow.client = { enable = true; server = "192.168.1.10"; };
#
# ### macOS client
#   Install via Homebrew: brew install deskflow/tap/deskflow
#   TLS is off by default; if enabling, accept fingerprints via the macOS GUI first.
#
# ### References
# - https://github.com/deskflow/deskflow
# - https://deskflow.org
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;

let
  cfgC = config.apps.network.deskflow.client;
  cfgS = config.apps.network.deskflow.server;

  # Screen layout config passed to deskflow-core via externalConfigFile in the settings file
  serverLayoutConfig = lib.mkIf cfgS.enable
    (pkgs.writeText "deskflow-layout.conf" ''
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

  # INI settings file consumed by deskflow-core -s
  # All runtime options live here rather than as CLI flags.
  serverSettingsFile = cfgS: pkgs.writeText "deskflow-server.conf" ''
    [core]
    coreMode=2
    screenName=${cfgS.name}
    ${lib.optionalString (cfgS.address != "") "interface=${cfgS.address}"}

    [security]
    tlsEnabled=${if cfgS.enableTls then "true" else "false"}

    [server]
    externalConfig=true
    externalConfigFile=/etc/deskflow-layout.conf
  '';

  clientSettingsFile = cfgC: pkgs.writeText "deskflow-client.conf" ''
    [core]
    coreMode=1
    screenName=${cfgC.name}
    ${lib.optionalString (cfgC.server != "") "remoteHost=${cfgC.server}"}

    [security]
    tlsEnabled=${if cfgC.enableTls then "true" else "false"}
  '';
in
{
  options = {
    apps.network.deskflow.server = {
      enable = lib.mkEnableOption "Deskflow server (KVM)";

      name = lib.mkOption {
        type = types.str;
        default = "server";
        description = "Screen name for this server. Clients must match this in their config.";
      };

      clientName = lib.mkOption {
        type = types.str;
        default = "client";
        description = "Screen name for the client in the generated layout config.";
      };

      address = lib.mkOption {
        type = types.str;
        default = "";
        description = "IP address on which to listen for clients. Defaults to all interfaces.";
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
          Enable TLS encryption. When enabling, the macOS client must also have TLS
          enabled and fingerprints accepted via the Deskflow GUI before headless operation.
        '';
      };
    };

    apps.network.deskflow.client = {
      enable = lib.mkEnableOption "Deskflow client (KVM)";

      name = lib.mkOption {
        type = types.str;
        default = "client";
        description = "Screen name for this client. Must match the server's clientName.";
      };

      server = lib.mkOption {
        type = types.str;
        default = "";
        description = "Server hostname or IP address to connect to.";
      };

      autoStart = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Whether the Deskflow client should be started automatically.";
      };

      enableTls = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Enable TLS encryption. Must match the server's enableTls setting.";
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

      # Screen layout config (which screens exist and their adjacency)
      environment.etc."deskflow-layout.conf".source = serverLayoutConfig;

      systemd.user.services.deskflow-server = {
        description = "Deskflow server";
        after = [ "network.target" "graphical-session.target" ];
        wantedBy = lib.optional cfgS.autoStart "graphical-session.target";
        path = [ pkgs.deskflow ];
        serviceConfig = {
          Restart = "on-failure";
          ExecStart = "${pkgs.deskflow}/bin/deskflow-core server -s ${serverSettingsFile cfgS} --new-instance";
        };
      };
    })

    # Client configuration
    (lib.mkIf cfgC.enable {
      systemd.user.services.deskflow-client = {
        description = "Deskflow client";
        after = [ "network.target" "graphical-session.target" ];
        wantedBy = lib.optional cfgC.autoStart "graphical-session.target";
        path = [ pkgs.deskflow ];
        serviceConfig = {
          Restart = "on-failure";
          ExecStart = "${pkgs.deskflow}/bin/deskflow-core client -s ${clientSettingsFile cfgC} --new-instance";
        };
      };
    })
  ];
}
