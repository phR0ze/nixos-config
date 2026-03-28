# Barrier options
#
# Barrier is KVM software that allows a single keyboard and mouse to control
# multiple computers. This module provides both server and client configurations.
#
# ### Usage
#   Server: apps.network.barrier.server.enable = true;
#   Client: apps.network.barrier.client = { enable = true; server = "192.168.1.10"; };
#
# ### References
# - https://github.com/debauchee/barrier
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;

let
  barrier = pkgs.callPackage ./package.nix {};

  cfgC = config.apps.network.barrier.client;
  cfgS = config.apps.network.barrier.server;

  barrierConfig = lib.mkIf cfgS.enable
    (pkgs.writeText "barrier.config" ''
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
    apps.network.barrier.server = {
      enable = lib.mkEnableOption "Barrier server (KVM)";

      configFile = lib.mkOption {
        type = types.path;
        default = "/etc/barrier.conf";
        description = "Barrier server configuration file.";
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
        description = "Address on which to listen for clients.";
      };

      autoStart = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Whether the Barrier server should be started automatically.";
      };

      enableCrypto = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Enable the crypto (SSL) plugin";
      };
    };

    apps.network.barrier.client = {
      enable = lib.mkEnableOption "Barrier client (KVM)";

      name = lib.mkOption {
        type = types.str;
        default = "client";
        description = "Make this name match what is expected in the screen configuration on the server.";
      };

      server = lib.mkOption {
        type = types.str;
        default = "";
        description = ''
          The server address is of the form: [hostname][:port]. The hostname must be the
          address or hostname of the server. The port overrides the default port, 24800.
        '';
      };

      enableCrypto = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Enable the crypto (SSL) plugin";
      };

      enableDragDrop = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Enable file drag and drop support";
      };

      autoStart = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Whether the client should be started automatically.";
      };
    };
  };

  config = lib.mkMerge [

    # Install barrier when either component is enabled
    (lib.mkIf (cfgC.enable || cfgS.enable) {
      environment.systemPackages = [ barrier ];
    })

    # Server configuration
    (lib.mkIf cfgS.enable {

      # Must allow clients to connect through the firewall
      # View rules with: sudo iptables -S
      networking.firewall.allowedTCPPorts = [ 24800 ];

      # Lay down the screen orientation default configuration
      environment.etc."barrier.conf".source = barrierConfig;

      systemd.user.services.barriers = {
        description = "Barrier server";
        after = [ "network.target" "graphical-session.target" ];
        wantedBy = lib.optional cfgS.autoStart "graphical-session.target";
        path = [ barrier ];
        serviceConfig.Restart = "on-failure";
        serviceConfig.ExecStart = toString (
          [ "${barrier}/bin/barriers -c ${cfgS.configFile} -f" ]
          ++ lib.optional (cfgS.address != "") "-a ${cfgS.address}"
          ++ lib.optional (cfgS.name != "") "-n ${cfgS.name}"
          ++ lib.optional (!cfgS.enableCrypto) "--disable-crypto"
        );
      };
    })

    # Client configuration
    (lib.mkIf cfgC.enable {
      systemd.user.services.barrierc = {
        description = "Barrier client";
        after = [ "network.target" "graphical-session.target" ];
        wantedBy = lib.optional cfgC.autoStart "graphical-session.target";
        path = [ barrier ];
        serviceConfig.Restart = "on-failure";
        serviceConfig.ExecStart = toString (
          [ "${barrier}/bin/barrierc -f" ]
          ++ lib.optional (cfgC.name != "") "-n ${cfgC.name}"
          ++ lib.optional (!cfgC.enableCrypto) "--disable-crypto"
          ++ lib.optional cfgC.enableDragDrop "--enable-drag-drop"
          ++ lib.optional (cfgC.server != "") "${cfgC.server}"
        );
      };
    })
  ];
}
