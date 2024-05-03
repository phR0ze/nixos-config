# Barrier options
#
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;

let
  cfgC = config.services.barrierc;
  cfgS = config.services.barriers;

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
    services.barrierc = {
      enable = lib.mkEnableOption (lib.mdDoc "Barrier client");

      name = lib.mkOption {
        type = types.str;
        default = "client";
        description = lib.mdDoc ''
          Make this name match what is expected in the screen configuration on the server.
        '';
      };

      server = lib.mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc ''
          The server address is of the form: [hostname][:port]. The hostname must be the
          address or hostname of the server. The port overrides the default port, 24800.
        '';
      };

      enableCrypto = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable the crypto (SSL) plugin";
      };

      enableDragDrop = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable file drag and drop support";
      };

      autoStart = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Whether the client should be started automatically.";
      };
    };

    services.barriers = {
      enable = lib.mkEnableOption (lib.mdDoc "Barrier server");

      configFile = lib.mkOption {
        type = types.path;
        default = "/etc/barrier.conf";
        description = lib.mdDoc "Barrier server configuration file.";
      };

      name = lib.mkOption {
        type = types.str;
        default = "server";
        description = lib.mdDoc ''
          Use this name for the server in the screen configuration.
        '';
      };

      clientName = lib.mkOption {
        type = types.str;
        default = "client";
        description = lib.mdDoc ''
          Use this name for the client in the screen configuration.
        '';
      };

      address = lib.mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Address on which to listen for clients.";
      };

      autoStart = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Whether the Barrier server should be started automatically.";
      };

      enableCrypto = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable the crypto (SSL) plugin";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfgC.enable || cfgS.enable) {
      environment.systemPackages = with pkgs; [ barrier ];
    })

    # Handle the server component configuration
    (lib.mkIf cfgS.enable {

      # Must allow clients to connect through the firewall
      # View rules with: sudo iptables -S
      networking.firewall.allowedTCPPorts = [ 24800 ];

      # Lay down the screen orientation default configuration
      environment.etc."barrier.conf".source = barrierConfig;

      # creates the /etc/systemd/user/graphical-session.target.wants/barriers.service link
      # to /etc/systemd/user/barriers.service
      systemd.user.services.barriers = {
        description = "Barrier server";
        after = [ "network.target" "graphical-session.target" ];
        wantedBy = lib.optional cfgS.autoStart "graphical-session.target";
        path = [ pkgs.barrier ];
        serviceConfig.Restart = "on-failure";
        serviceConfig.ExecStart = toString (
          [ "${pkgs.barrier}/bin/barriers -c ${cfgS.configFile} -f" ]
          ++ lib.optional (cfgS.address != "") "-a ${cfgS.address}"
          ++ lib.optional (cfgS.name != "") "-n ${cfgS.name}"
          ++ lib.optional (!cfgS.enableCrypto) "--disable-crypto"
        );
      };
    })

    # Handle the client component configuration
    (lib.mkIf cfgC.enable {

      # creates the /etc/systemd/user/graphical-session.target.wants/barrierc.service link
      # to /etc/systemd/user/barrierc.service
      systemd.user.services.barrierc = {
        description = "Barrier client";
        after = [ "network.target" "graphical-session.target" ];
        wantedBy = lib.optional cfgC.autoStart "graphical-session.target";
        path = [ pkgs.barrier ];
        serviceConfig.Restart = "on-failure";
        serviceConfig.ExecStart = toString (
          [ "${pkgs.barrier}/bin/barrierc -f" ]
          ++ lib.optional (cfgC.name != "") "-n ${cfgC.name}"
          ++ lib.optional (!cfgC.enableCrypto) "--disable-crypto"
          ++ lib.optional cfgC.enableDragDrop "--enable-drag-drop"
          ++ lib.optional (cfgC.server != "") "${cfgC.server}"
        );
      };
    })
  ];
}
