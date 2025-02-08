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
# - Linux is X11 support only for now
#
# --------------------------------------------------------------------------------------------------
{ config, lib, f, ... }: with lib.types;
let
  cfg = config.services.rustdesk;
  machine = config.machine;
in
{
  options = {
    services.rustdesk = {
      enable = lib.mkEnableOption "Install and configure rustdesk server";
      relayHost = lib.mkOption {
        description = lib.mdDoc "IP/DNS name to use for the relay host";
        type = types.str;
        example = "192.168.1.2";
        default = config.networking.primary.ip;
      };
    };
  };
 
  config = lib.mkIf (cfg.enable) {
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
  };
}
