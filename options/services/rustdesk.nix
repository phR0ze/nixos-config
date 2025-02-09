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
# - Sciter based client being migrated to Flutter
# - Linux is X11 support only for now
#
# ### Configuration string
# RustDesk supports encoding settings into the filename
# - https://github.com/v0tti/rustdesk-configstring
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.services.rustdesk;
  machine = config.machine;

#  rustdesk --password $rustdesk_pw &> /dev/null
#  rustdesk --config $rustdesk_cfg
#  systemctl restart rustdesk
in
{
  options = {
    services.rustdesk.client = {
      enable = lib.mkEnableOption "Install and configure rustdesk client";
      acceptSessionViaClick = lib.mkOption {
        description = lib.mdDoc ''
          Prompt the remote user to click accept in order to connect to the session.
          Note this can be used with the password option to allow for both options.
        '';
        type = types.bool;
        default = true;
      };
      acceptSessionViaPassword = lib.mkOption {
        description = lib.mdDoc ''
          Accept RustDesk sessions after entering the password without prompting the remote user to 
          click accept. Note this can be used with the click option to allow for both options.
        '';
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

    # Configure client
    (lib.mkIf (cfg.client.enable) {

      # Install the rustdesk Sciter client
      environment.systemPackages = [
        pkgs.rustdesk
      ];

      # Open up ports for the client to receive connections
      networking.firewall.allowedTCPPorts = [ 21115 21116 21117 21118 21119 ];
      networking.firewall.allowedUDPPorts = [ 21116 ];

      # Configure options for rustdesk
      # - permanent password is stored in /home/$user/.config/rustdesk/RustDesk.toml
      #   enc_id = 'encrypted_value'
      #   password = 'encrypted_value'
      #   salt = 'value'
      # - options are stored in /home/$user/.config/rustdesk/RustDesk2.toml
      #   [options]
      #   verification-method = "use-permanent-password"
      #   approve-mode = "password"
      files.user.".config/rustdesk/RustDesk2.toml".text = ''
        [options]
        verification-method = "use-permanent-password"
        approve-mode = "${if cfg.client.acceptSessionViaPassword then 'password' else (
          if cfg.client.acceptSessionViaClick then 'password' else (
            if cfg.client.acceptSessionViaClick then 'click' else (
        )}"
      ''
      # Optionally add approve-mode selection
      + lib.optionalString (cfg.client.acceptSessionViaClick) ''approve-mode = "click"''
      + lib.optionalString (cfg.client.acceptSessionViaPassword) ''approve-mode = "password"''
      ;
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
