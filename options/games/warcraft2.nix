# Warcraft2
#
# Firewall configuration
# * UDP: 40000 - 60000
# * TCP: 54792
# Battle.net: UDP 6112 - 6119
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.programs.warcraft2;

in
{
  options = {
    programs.warcraft2 = {
      enable = lib.mkEnableOption "Configure system for warcraft2";
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
    networking.firewall = lib.optional cfg.allowIPXMultiPlayer {
      allowedTCPPorts = [ 54792 ];
      allowedUDPPortRanges = [ { from = 40000; to = 60000; } ]; 
    };
}
