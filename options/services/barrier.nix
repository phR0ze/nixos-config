# Barrier options
#
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;

let
  cfg = config.services.barrier;
  cfgC = config.services.barrier.client;
  cfgS = config.services.barrier.server;

in
{
  options = {
    services.barrier = {
      enable = lib.mkEnableOption (
        lib.mdDoc "Barrier is an open source software KVM solution");

      client = {
        enable = lib.mkEnableOption (lib.mdDoc "Barrier client");

        name = lib.mkOption {
          type = types.str;
          default = "";
          description = lib.mdDoc ''
            Use the given name instead of the hostname to identify
            ourselves to the server.
          '';
        };

        server = lib.mkOption {
          type = types.str;
          default = "";
          description = lib.mdDoc ''
            The server address is of the form: [hostname][:port].  The
            hostname must be the address or hostname of the server.  The
            port overrides the default port, 24800.
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

      server = {
        enable = lib.mkEnableOption (lib.mdDoc "Barrier server");

        configFile = lib.mkOption {
          type = types.path;
          default = "/etc/barrier.conf";
          description = lib.mdDoc "Barrier server configuration file.";
        };

        name = lib.mkOption {
          type = types.str;
          default = "";
          description = lib.mdDoc ''
            Use the given name instead of the hostname to identify
            this screen in the configuration.
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
  };

  config = mkMerge [
    (lib.mkIf (cfg.enable || cfgC.enable || cfgS.enable) {
      environment.systemPackages = with pkgs; [ barrier ];
    })
    (mkIf (cfg.enable || cfgC.enable) {
      systemd.user.services.barrierc = {
        description = "Barrier client";
        after = [ "network.target" "graphical-session.target" ];
        wantedBy = optional cfgC.autoStart "graphical-session.target";
        path = [ pkgs.barrier ];
        serviceConfig.Restart = "on-failure";
        serviceConfig.ExecStart = lib.toString (
          [ "${pkgs.barrier}/bin/barrierc -f" ]
          ++ lib.optional (cfgC.name != "") "-n ${cfgC.name}"
          ++ optional (!cfgC.enableCrypto) "--disable-crypto"
          ++ optional cfgC.enableDragDrop "--enable-drag-drop"
          ++ lib.optional (cfgC.server != "") "${cfgC.server}"
        );
      };
    })
    (mkIf (cfg.enable || cfgS.enable) {
      systemd.user.services.barriers = {
        description = "Barrier server";
        after = [ "network.target" "graphical-session.target" ];
        wantedBy = optional cfgS.autoStart "graphical-session.target";
        path = [ pkgs.barrier ];
        serviceConfig.Restart = "on-failure";
        serviceConfig.ExecStart = lib.toString (
          [ "${pkgs.barrier}/bin/barriers -c ${cfgS.configFile} -f" ]
          ++ lib.optional (cfgS.address != "") "-a ${cfgS.address}"
          ++ lib.optional (cfgS.name != "") "-n ${cfgS.name}"
          ++ optional (!cfgS.enableCrypto) "--disable-crypto"
        );
      };
    })
  ];
}

/* barrier server example configuration file
section: screens
	main:
	laptop:
end

section: links
	main:
		right = laptop
	laptop:
		left = main
end
*/
