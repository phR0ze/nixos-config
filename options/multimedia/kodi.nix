# kodi
# A software media player and entertainment hub for digital media
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.programs.kodi;

in
{
  options = {
    programs.kodi = {
      enable = lib.mkEnableOption "Install and configure kodi";
      port = lib.mkOption {
        type = types.port;
        default = 8080;
        description = lib.mdDoc "Port to use for remote control.";
      };
      remoteControlHTTP = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable HTTP remote control.";
      };
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ kodi ];

    # Allow remote control through the firewall
    # View rules with: sudo iptables -S
    networking.firewall.allowedTCPPorts = lib.optional cfg.remoteControlHTTP cfg.port;
  };
}
