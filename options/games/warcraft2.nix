# Warcraft2
#
# * Firewall configuration
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.programs.warcraft2;

in
{
  options = {
    programs.warcraft2 = {
      enable = lib.mkEnableOption "Configure system for warcraft2";
      port = lib.mkOption {
        type = types.port;
        default = 54792;
        description = lib.mdDoc "Port used for IPX multi-player";
      };
      allowIPXMultiPlayer= lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Enable firewall rules for IPX multi-player.";
      };
    };
  };
 
  config = lib.mkIf (cfg.enable) {

    # Allow multi-player IPX connections through the firewall
    # View rules with: sudo iptables -S
    networking.firewall.allowedTCPPorts = lib.optional cfg.allowIPXMultiPlayer cfg.port;
  };
}
